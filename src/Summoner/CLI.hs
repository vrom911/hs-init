{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QuasiQuotes   #-}
{-# LANGUAGE TupleSections #-}

-- | This module contains functions and data types to parse CLI inputs.

module Summoner.CLI
       ( summon
       ) where

import NeatInterpolation (text)
import Options.Applicative (Parser, ParserInfo, command, execParser, flag, fullDesc, help, helper,
                            info, infoFooter, infoHeader, long, metavar, optional, progDesc, short,
                            strArgument, strOption, subparser)
import Options.Applicative.Help.Chunk (stringChunk)
import System.Directory (doesFileExist)

import Summoner.Ansi (boldText, errorMessage, infoMessage, warningMessage)
import Summoner.Config (ConfigP (..), PartialConfig, defaultConfig, finalise, loadFileConfig)
import Summoner.Default (defaultConfigFile, endLine)
import Summoner.Project (generateProject)
import Summoner.ProjectData (Decision (..))
import Summoner.Validation (Validation (..))

---------------------------------------------------------------------------
-- CLI
----------------------------------------------------------------------------

summon :: IO ()
summon = execParser prsr >>= runWithOptions

-- | Run 'hs-init' with cli options
runWithOptions :: InitOpts -> IO ()
runWithOptions (InitOpts projectName maybeFile cliConfig) = do
    (isDefault, file) <- case maybeFile of
        Nothing -> (True,) <$> defaultConfigFile
        Just x  -> pure (False, x)
    isFile <- doesFileExist file
    fileConfig <-
        if isFile
        then do
            infoMessage $ "Configurations from " <> toText file <> " will be used."
            loadFileConfig file
        else if isDefault
              then do
                  fp <- toText <$> defaultConfigFile
                  warningMessage $ "Default config " <> fp <> " file is missing."
                  pure mempty
              else do
                  errorMessage $ "Specified configuration file " <> toText file <> " is not found."
                  exitFailure
    -- union all possible configs
    let unionConfig = defaultConfig <> fileConfig <> cliConfig
    -- get the final config
    finalConfig <- case finalise unionConfig of
             Failure msgs -> do
                 for_ msgs errorMessage
                 exitFailure
             Success c    ->  pure c
    -- Generate the project.
    generateProject projectName finalConfig

    boldText "\nJob's done\n"

-- | Initial parsed options from cli
data InitOpts = InitOpts Text (Maybe FilePath) PartialConfig
    -- ^ Includes the project name, config from the CLI and possible file where custom congifs are.

targetsP ::  Decision -> Parser PartialConfig
targetsP d = do
    cGitHub  <- githubP    d
    cTravis  <- travisP    d
    cAppVey  <- appVeyorP  d
    cPrivate <- privateP   d
    cScript  <- scriptP    d
    cLib     <- libraryP   d
    cExe     <- execP      d
    cTest    <- testP      d
    cBench   <- benchmarkP d
    pure mempty
        { cGitHub = cGitHub
        , cTravis = cTravis
        , cAppVey = cAppVey
        , cPrivate= cPrivate
        , cScript = cScript
        , cLib    = cLib
        , cExe    = cExe
        , cTest   = cTest
        , cBench  = cBench
        }

githubP :: Decision -> Parser Decision
githubP d = flag Idk d
          $ long "github"
         <> short 'g'
         <> help "GitHub integration"

travisP :: Decision -> Parser Decision
travisP d = flag Idk d
          $ long "travis"
         <> short 'c'
         <> help "Travis CI integration"

appVeyorP :: Decision -> Parser Decision
appVeyorP d = flag Idk d
            $ long "app-veyor"
           <> short 'w'
           <> help "AppVeyor CI integration"

privateP :: Decision -> Parser Decision
privateP d = flag Idk d
           $ long "private"
          <> short 'p'
          <> help "Private repository"

scriptP :: Decision -> Parser Decision
scriptP d = flag Idk d
          $ long "script"
         <> short 's'
         <> help "Build script for convenience"

libraryP :: Decision -> Parser Decision
libraryP d = flag Idk d
           $ long "library"
          <> short 'l'
          <> help "Library folder"

execP :: Decision -> Parser Decision
execP d = flag Idk d
        $ long "exec"
       <> short 'e'
       <> help "Executable target"

testP :: Decision -> Parser Decision
testP d =  flag Idk d
        $  long "test"
        <> short 't'
        <> help "Test target"

benchmarkP :: Decision -> Parser Decision
benchmarkP d = flag Idk d
             $ long "benchmark"
            <> short 'b'
            <> help "Benchmarks"

withP :: Parser PartialConfig
withP = subparser $ mconcat
    [ metavar "with [OPTIONS]"
    , command "with" $ info (helper <*> targetsP Yes) (progDesc "Specify options to enable")
    ]

withoutP :: Parser PartialConfig
withoutP = subparser $ mconcat
    [ metavar "without [OPTIONS]"
    , command "without" $ info (helper <*> targetsP Nop) (progDesc "Specify options to disable")
    ]

fileP :: Parser FilePath
fileP = strOption
    $ long "file"
   <> short 'f'
   <> metavar "FILENAME"
   <> help "Path to the toml file with configurations. If not specified '~/summoner.toml' will be used if present"

preludePackP :: Parser Text
preludePackP = strOption
    $ long "package"
   <> metavar "CUSTOM_PRELUDE_PACKAGE"
   <> help "Name for the package of the custom prelude to use in the project"

preludeModP :: Parser Text
preludeModP = strOption
    $ long "module"
   <> metavar "CUSTOM_PRELUDE_MODULE"
   <> help "Name for the module of the custom prelude to use in the project"

optsP :: Parser InitOpts
optsP = do
    projectName <- strArgument (metavar "PROJECT_NAME")
    with    <- optional withP
    without <- optional withoutP
    file    <- optional fileP
    preludePack <- optional preludePackP
    preludeMod  <- optional preludeModP

    pure $ InitOpts projectName file
        $ (maybeToMonoid $ with <> without)
            { cPreludePackage = Last preludePack
            , cPreludeModule  = Last preludeMod
            }

prsr :: ParserInfo InitOpts
prsr = modifyHeader
     $ modifyFooter
     $ info ( helper <*> optsP )
            $ fullDesc
           <> progDesc "Create your own haskell project"

-- to put custom header which doesn't cut all spaces
modifyHeader :: ParserInfo InitOpts -> ParserInfo InitOpts
modifyHeader initOpts = initOpts {infoHeader = stringChunk $ toString artHeader}

-- to put custom footer which doesn't cut all spaces
modifyFooter :: ParserInfo InitOpts -> ParserInfo InitOpts
modifyFooter initOpts = initOpts {infoFooter = stringChunk $ toString artFooter}

artHeader :: Text
artHeader = [text|
$endLine
                                                   ___
                                                 /  .  \
                                                │\_/│   │
                                                │   │  /│
  ___________________________________________________-' │
 ╱                                                      │
╱   .-.                                                 │
│  /   \                                                │
│ |\_.  │ Summoner — tool for creating Haskell projects │
│\|  | /│                                               │
│ `-_-' │                                              ╱
│       │_____________________________________________╱
│       │
 ╲     ╱
  `-_-'
|]

artFooter :: Text
artFooter = [text|
$endLine
          ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ________┃                                  ┃_______
  ╲       ┃   λ Make Haskell Great Again λ   ┃      ╱
   ╲      ┃                                  ┃     ╱
   ╱      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛     ╲
  ╱__________)                            (_________╲

|]
