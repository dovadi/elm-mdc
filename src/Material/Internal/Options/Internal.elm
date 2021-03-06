module Material.Internal.Options.Internal exposing (..)

import Html.Attributes
import Html.Events
import Html exposing (Html, Attribute)
import Json.Decode as Json exposing (Decoder)
import Material.Internal.Dispatch as Dispatch
import Material.Internal.Msg exposing (Msg(..))
import String


type Property c m
    = Class String
    | CSS ( String, String )
    | Attribute (Html.Attribute m)
    | Internal (Html.Attribute m)
    | Many (List (Property c m))
    | Set (c -> c)
    | Listener String (Maybe Html.Events.Options) (Decoder m)
    | Lift (Decoder (List m) -> Decoder m)
    | None


{-| Contents of a `Property c m`.
-}
type alias Summary c m =
    { classes : List String
    , css : List ( String, String )
    , attrs : List (Attribute m)
    , internal : List (Attribute m)
    , dispatch : Dispatch.Config m
    , config : c
    }


attribute : Html.Attribute m -> Property c m
attribute =
    Internal


{- `collect` and variants are called multiple times by nearly every use of
   any elm-mdc component. Carefully consider performance implications before
   modifying. In particular:

   - Avoid closures. They are slow to create and cause subsequent GC.
   - Pre-compute where possible.

   Earlier versions of `collect`, violating these rules, consumed ~20% of
   execution time for `Cards.view` and `Textfield.view`.
-}
collect1 : Property c m -> Summary c m -> Summary c m
collect1 option acc =
    case option of
        Class x ->
            { acc | classes = x :: acc.classes }

        CSS x ->
            { acc | css = x :: acc.css }

        Attribute x ->
            { acc | attrs = x :: acc.attrs }

        Internal x ->
            { acc | internal = x :: acc.internal }

        Many options ->
            List.foldl collect1 acc options

        Set g ->
            { acc | config = g acc.config }

        Listener event options decoder ->
            { acc | dispatch = Dispatch.add event options decoder acc.dispatch }

        Lift m ->
            { acc | dispatch = Dispatch.setDecoder m acc.dispatch }

        None ->
            acc


recollect : Summary c m -> List (Property c m) -> Summary c m
recollect =
    List.foldl collect1


{-| Flatten a `Property a` into  a `Summary a`. Operates as `fold`
over options; first two arguments are folding function and initial value.
-}
collect : c -> List (Property c m) -> Summary c m
collect =
    Summary [] [] [] [] Dispatch.defaultConfig >> recollect


{-| Special-casing of collect for `Property c ()`.
-}
collect1_ : Property c m -> Summary () m -> Summary () m
collect1_ options acc =
    case options of
        Class x ->
            { acc | classes = x :: acc.classes }

        CSS x ->
            { acc | css = x :: acc.css }

        Attribute x ->
            { acc | attrs = x :: acc.attrs }

        Internal x ->
            { acc | internal = x :: acc.internal }

        Listener event options decoder ->
            { acc | dispatch = Dispatch.add event options decoder acc.dispatch }

        Many options ->
            List.foldl collect1_ acc options

        Lift m ->
            { acc | dispatch = Dispatch.setDecoder m acc.dispatch }

        Set _ ->
            acc

        None ->
            acc


collect_ : List (Property c m) -> Summary () m
collect_ =
    List.foldl collect1_ (Summary [] [] [] [] Dispatch.defaultConfig ())


addAttributes : Summary c m -> List (Attribute m) -> List (Attribute m)
addAttributes summary attrs =
    {- Ordering here is important: First apply summary attributes. That way,
       internal classes and attributes override those provided by the user.
    -}
    summary.attrs
        ++ [ Html.Attributes.style summary.css
           , Html.Attributes.class (String.join " " summary.classes)
           ]
        ++ attrs
        ++ summary.internal
        ++ Dispatch.toAttributes summary.dispatch


{-| Apply a `Summary m`, extra properties, and optional attributes
to a standard Html node.
-}
apply :
    Summary c m
    -> (List (Attribute m) -> a)
    -> List (Property c m)
    -> List (Attribute m)
    -> a
apply summary ctor options attrs =
    ctor
        (addAttributes
            (recollect summary options)
            attrs
        )


option : (c -> c) -> Property c m
option =
    Set


nativeControl : List (Property c m)
    -> Property { a | nativeControl : List (Property c m) } m
nativeControl options =
    option (\config -> { config | nativeControl = config.nativeControl ++ options })


dispatch : (Msg m -> m) -> Property c m 
dispatch lift =
    Lift (Json.map Dispatch >> Json.map lift)


{-| Inject dispatch
-}
inject
  : (a -> b -> List (Property c m) -> d)
  -> (Msg m -> m)
  -> a
  -> b
  -> List (Property c m)
  -> d   
inject view lift a b c =
    view a b (dispatch lift :: c)


{-| Construct lifted handler with trivial decoder in a manner that
virtualdom will like.

vdom diffing will recognise two different executions of the following to be
identical:

    Json.map lift <| Json.succeed m    -- (a)

vdom diffing will _not_ recognise two different executions of this seemingly
simpler variant to be identical:

    Json.succeed (lift m)              -- (b)

In the common case, both `lift` and `m` will be a top-level constructors, say
`Mdl` and `Click`. In this case, the `lift m` in (b) is constructed anew on
each `view`, and vdom can't tell that the argument to Json.succeed is the same.
In (a), though, we're constructing no new values besides a Json decoder, which
will be taken apart as part of vdoms equality check; vdom _can_ in this case
tell that the previous and current decoder is the same.

See #221 / this thread on elm-discuss:
https://groups.google.com/forum/#!topic/elm-discuss/Q6mTrF4T7EU
-}
on1 : String -> (a -> b) -> a -> Property c b
on1 event lift m =
    Listener event Nothing (Json.map lift <| Json.succeed m)
