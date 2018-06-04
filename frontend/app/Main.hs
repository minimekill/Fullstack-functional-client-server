{-# LANGUAGE OverloadedStrings #-}
{-# lANGUAGE DeriveGeneric #-}

module Main where
import Control.Concurrent (newMVar, readMVar, takeMVar, putMVar)
import Control.Monad.Trans.Class (lift)
import Data.IntMap (IntMap)
import qualified Data.IntMap.Strict as IntMap
import GHC.Generics
import Data.Aeson(FromJSON, ToJSON)
import Prelude hiding (id)
import Network.Wai.Middleware.Cors
import Web.Scotty

main :: IO ()
main = do
  newMembersRef <- newMVar $ IntMap.fromList [(1,Member 1 "Kurt" "kurt@email.com"),
                                              (2, Member 2 "lars" "lars@gmail.com")]
  scotty 9000 $ do
    middleware simpleCors
    get "/hello/:name" $ do
      name <- param "name"
      html $ mconcat [ "<h1>Hello ", name, " from Scotty!</h1><hr/>"]
    get "/member/count" $ do
      members <- lift $ readMVar newMembersRef
      json (IntMap.size members)
    get "/member/:id" $ do
      tempid <- param "id"
      members <- lift $ readMVar newMembersRef
      let idx = (read tempid) :: Int
      json(IntMap.lookup idx members)
    post "/member" $ do
      member <- jsonData
      beforeMembers <- lift $ takeMVar newMembersRef
      let (updatedMember, afterMembers) = insertMember member beforeMembers
      lift $ putMVar newMembersRef afterMembers
      json(updatedMember)

-- data type
-- Just like making the maybe case, we had just and nothing, here we have "member" could have called it anything
data Member = Member { id :: Int
 ,name :: String
 ,email :: String
 } deriving (Show, Generic)

instance ToJSON Member

instance FromJSON Member

insertMember :: Member -> IntMap Member -> (Member, IntMap Member)
insertMember member members =
  if IntMap.member (id member) members then
    (member,IntMap.insert (id member) member members)
  else
    let
      m = Member ((IntMap.size members) + 1) (name member)(email member)
    in
      (m, IntMap.insert (id member) member members)

newMembersRef :: IO(IntMap Member)
newMembersRef = do
  temp <- newMVar IntMap.empty
  takeMVar temp
