import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode

main : Program Never Model Msg
main =
  Html.program
    { init = start
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

url : String -> String
url action = "http://localhost:9000/member/" ++ action

-- MODEL

type alias Model =
  { count : Int
  , message : String
  , member : Member
  , number : Int
  }

start : (Model, Cmd Msg)
start =
  ( Model 0 "No message" (Member 0 "peter" "mail") 0
  , Cmd.none
  )

-- UPDATE

type Msg
  = GetMemberCount
  | MemberCountReceived (Result Http.Error Int)
  | GetMember
  | MemberRecieved (Result Http.Error Member)
  | ID String
  | Name String
  | Email String
  | PostMember
  | MemberPosted (Result Http.Error Member)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetMemberCount ->
      (model, getMemberCount)

    MemberCountReceived (Ok newCount) ->
      ( { model | count = newCount }, Cmd.none)

    MemberCountReceived (Err error) ->
      ( { model | message = toString error }, Cmd.none)

    GetMember ->
      (model, getMember model.member.idd)

    MemberRecieved (Ok theMember ) ->
      --(model,Cmd.none)
      ({ model | member = theMember}, Cmd.none)

    MemberRecieved (Err error) ->
      ({model | message = toString error}, Cmd.none)

    ID idText ->
      case String.toInt idText of
        Ok id ->
          ({model | member = (Member id model.member.name model.member.email)},Cmd.none)
        Err id ->
          ({model | member = (Member 0 model.member.name model.member.email),
          message = "FAIL"},Cmd.none)
    Name name ->
      let
        member = model.member
      in
        ({model | member = { member | name = name}},Cmd.none)
    Email email ->
      let
        member = model.member
      in
        ({model | member = { member | email = email}},Cmd.none)
    PostMember ->
      (model, postMember model.member)

    MemberPosted (Ok theMember) ->
      ({model | member = theMember},getMemberCount)

    MemberPosted (Err error) ->
      ({model | message = toString error},Cmd.none)


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ h2 [] [text ("Member Count = " ++ toString model.count) ]
    , button [ onClick GetMemberCount ] [ text "Update Member Count" ]
    , button [ onClick PostMember ] [text "save member"]
    , input [type_  "text", value (toString model.member.idd), onInput ID][]
    , input [type_  "text", value model.member.name, onInput Name][]
    , input [type_  "text", value model.member.email, onInput Email][]
    , h2 [] [text (toString model.member.idd ++ " " ++ toString model.member.name ++ " " ++ toString model.member.email)]
    , hr [] []
    , text model.message
    ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

-- HTTP

getMemberCount : Cmd Msg
getMemberCount =
    Http.send MemberCountReceived (Http.get (url "count") Decode.int)



-- Record

type alias Member =
  {idd : Int
  , name : String
  , email : String}

--decodeMember =
--  Http.send (Http.get (url "1")Decode.)
decodeMember : Decode.Decoder Member
decodeMember =
  Decode.map3 Member
  (Decode.field "id" Decode.int )
  (Decode.field "name" Decode.string)
  (Decode.field "email" Decode.string)

encodeMember : Member -> Encode.Value
encodeMember member =
  Encode.object [
   ("id", Encode.int member.idd)
  , ("name", Encode.string member.name)
  , ("email", Encode.string member.email)
  ]

getMember : Int -> Cmd Msg
getMember id =
  Http.send MemberRecieved (Http.get(url (toString id)) decodeMember)

memberJsonBody : Member -> Http.Body
memberJsonBody member =
  Http.jsonBody <| encodeMember member

postMember : Member -> Cmd Msg
postMember member =
  Http.send MemberPosted (Http.post (url "") (memberJsonBody member) decodeMember)
