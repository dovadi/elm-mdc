module Material.Internal.FormField.Implementation exposing
    ( alignEnd
    , Property
    , view
    )

import Html exposing (Html)
import Material.Internal.Options as Options exposing (styled, cs)


type alias Config =
    {}


type alias Property m =
    Options.Property Config m


view : List (Property m) -> List (Html m) -> Html m
view options =
    styled Html.div (cs "mdc-form-field" :: options)


alignEnd : Property m
alignEnd =
    cs "mdc-form-field--align-end"
