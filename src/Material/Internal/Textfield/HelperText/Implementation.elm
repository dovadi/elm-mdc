module Material.Internal.Textfield.HelperText.Implementation exposing
    ( helperText
    , persistent
    , Property
    , validationMsg
    )

import Html exposing (Html)
import Material.Internal.Options as Options exposing (cs, css, when)
import Material.Internal.Options.Internal as Internal


type alias Config =
    { persistent : Bool
    , validationMsg : Bool
    }


defaultConfig : Config
defaultConfig =
    { persistent = False
    , validationMsg = False
    }


type alias Property m =
    Options.Property Config m


persistent : Property m
persistent =
    Internal.option (\config -> { config | persistent = True })


validationMsg : Property m
validationMsg =
    Internal.option (\config -> { config | validationMsg = True })


helperText : List (Property m) -> List (Html m) -> Html m
helperText options =
    let
        ({ config } as summary) =
            Internal.collect defaultConfig options
    in
    Options.styled Html.p
    (  cs "mdc-text-field-helper-text"
    :: (cs "mdc-text-field-helper-text--persistent" |> when config.persistent)
    :: (cs "mdc-text-field-helper-text--validation-msg" |> when config.validationMsg)
    :: options
    )
