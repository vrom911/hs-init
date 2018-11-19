{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE TemplateHaskell        #-}

{- | This module contains data types to work with application form.
'SummonKit' is the data type containing the values manipulated by the fields
in the form.
-}

module Summoner.Tui.Kit
       ( -- * Data types
         SummonKit (..)
       , initialSummonKit

         -- * Lenses
         -- ** SummonKit
       , user
       , project
       , cabal
       , stack
       , gitHub

         -- ** User
       , owner
       , fullName
       , email

         -- ** Project
       , repo
       , desc
       , category
       , license
       , maybeLicense

         -- ** GitHub
       , enabled
       , private
       , travis
       , appVeyor
       ) where

import Lens.Micro (Lens', lens, (.~))
import Lens.Micro.TH (makeFields)

import Summoner.License (LicenseName (..))


-- | Global TUI state.
data SummonKit = SummonKit
    { summonKitUser    :: User
    , summonKitProject :: Project
    , summonKitCabal   :: Bool
    , summonKitStack   :: Bool
    , summonKitGitHub  :: GitHub
    } deriving (Show)

data User = User
    { userOwner    :: Text
    , userFullName :: Text
    , userEmail    :: Text
    } deriving (Show)

data Project = Project
    { projectRepo     :: Text
    , projectDesc     :: Text
    , projectCategory :: Text
    , projectLicense  :: LicenseName
    } deriving (Show)

data GitHub = GitHub
    { gitHubEnabled  :: Bool
    , gitHubPrivate  :: Bool
    , gitHubTravis   :: Bool
    , gitHubAppVeyor :: Bool
    } deriving (Show)

-- | Initial global state of the tui.
initialSummonKit :: SummonKit
initialSummonKit = SummonKit
    { summonKitUser  = User
        { userOwner = ""
        , userFullName = ""
        , userEmail = ""
        }
    , summonKitProject = Project
        { projectRepo = ""
        , projectDesc = ""
        , projectCategory = ""
        , projectLicense = MIT
        }
    , summonKitCabal = False
    , summonKitStack = False
    , summonKitGitHub = GitHub
        { gitHubEnabled  = True
        , gitHubPrivate  = False
        , gitHubTravis   = False
        , gitHubAppVeyor = False
        }
    }

makeFields ''SummonKit
makeFields ''User
makeFields ''Project
makeFields ''GitHub

maybeLicense :: Lens' SummonKit (Maybe LicenseName)
maybeLicense = lens getL setL
  where
    getL :: SummonKit -> Maybe LicenseName
    getL = Just . projectLicense . summonKitProject

    setL :: SummonKit -> Maybe LicenseName -> SummonKit
    setL sk mbL = case mbL of
        Just l  -> sk & project . license .~ l
        Nothing -> sk