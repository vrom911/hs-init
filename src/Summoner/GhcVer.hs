module Summoner.GhcVer
       ( GhcVer (..)
       , Pvp (..)
       , showGhcVer
       , parseGhcVer
       , latestLts
       , baseVer
       , cabalBaseVersions
       ) where

import Data.List (maximum, minimum)

import qualified Text.Show as Show


-- | Represents some selected set of GHC versions.
data GhcVer
    = Ghc7103
    | Ghc801
    | Ghc802
    | Ghc822
    | Ghc843
    | Ghc844
    deriving (Eq, Ord, Show, Enum, Bounded)

-- | Converts 'GhcVer' into dot-separated string.
showGhcVer :: GhcVer -> Text
showGhcVer = \case
    Ghc7103 -> "7.10.3"
    Ghc801  -> "8.0.1"
    Ghc802  -> "8.0.2"
    Ghc822  -> "8.2.2"
    Ghc843  -> "8.4.3"
    Ghc844  -> "8.4.4"

parseGhcVer :: Text -> Maybe GhcVer
parseGhcVer = inverseMap showGhcVer

-- | Returns latest known LTS resolver for all GHC versions except default one.
latestLts :: GhcVer -> Text
latestLts = \case
    Ghc7103 -> "6.35"
    Ghc801  -> "7.24"
    Ghc802  -> "9.21"
    Ghc822  -> "11.22"
    Ghc843  -> "12.14"
    Ghc844  -> "12.17"

-- | Represents PVP versioning (4 numbers).
data Pvp = Pvp
    { pvpFirst  :: Int
    , pvpSecond :: Int
    , pvpThird  :: Int
    , pvpFourth :: Int
    }

-- | Show PVP version in a standard way: @1.2.3.4@
instance Show Pvp where
    show (Pvp a b c d) = intercalate "." $ map Show.show [a, b, c, d]

-- | Returns base version by 'GhcVer' as 'Pvp'.
baseVerPvp :: GhcVer -> Pvp
baseVerPvp = \case
    Ghc7103 -> Pvp 4 8 0 2
    Ghc801  -> Pvp 4 9 0 0
    Ghc802  -> Pvp 4 9 1 0
    Ghc822  -> Pvp 4 10 1 0
    Ghc843  -> Pvp 4 11 1 0
    Ghc844  -> Pvp 4 11 1 0

baseVer :: GhcVer -> Text
baseVer = show . baseVerPvp

cabalBaseVersions :: [GhcVer] -> Text
cabalBaseVersions []   = ""
cabalBaseVersions [v]  = "^>= " <> baseVer v
cabalBaseVersions ghcs = ">= " <> baseVer (minimum ghcs) <> " && < " <> upperBound
  where
    upperBound :: Text
    upperBound = let Pvp{..} = baseVerPvp $ maximum ghcs in
        show pvpFirst <> "." <> show (pvpSecond + 1)
