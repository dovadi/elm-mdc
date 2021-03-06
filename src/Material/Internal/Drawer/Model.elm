module Material.Internal.Drawer.Model exposing
    ( Msg(..)
    , Geometry
    , defaultGeometry
    )


type Msg
    = NoOp
    | Tick
    | Click

    | Open Bool
    | Close
    | Toggle Bool


type alias Geometry =
    { width : Float
    }


defaultGeometry : Geometry
defaultGeometry =
    { width = 0
    }
