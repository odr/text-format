{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RelaxedPolyRec    #-}

-- |
-- Module      : Data.Text.Format
-- Copyright   : (c) 2011 MailRank, Inc.
--
-- License     : BSD-style
-- Maintainer  : bos@serpentine.com
-- Stability   : experimental
-- Portability : GHC
--
-- Fast, efficient, flexible support for formatting text strings.

module Data.Text.Format
    (
    -- * Types
      Format
    , Only(..)
    -- ** Types for format control
    , Shown(..)
    -- * Rendering
    , format
    , print
    , hprint
    , build
    -- * Format control
    , left
    , right
    -- ** Integers
    , hex
    ) where

import           Control.Monad.IO.Class (MonadIO(liftIO))
-- import qualified Data.Double.Conversion.Text as C
import qualified Data.Text as ST
import qualified Data.Text.Buildable as B
import           Data.Text.Format.Params (Params(..))
import           Data.Text.Format.Types.Internal
  (Format(..), Only(..), Shown(..))
import           Data.Text.Format.Types.Internal (Hex(..))
import qualified Data.Text.Lazy as LT
import           Data.Text.Lazy.Builder
import qualified Data.Text.Lazy.IO as LT
import           Prelude hiding (exp, print)
import           System.IO (Handle)

-- Format strings are almost always constants, and they're expensive
-- to interpret (which we refer to as "cracking" here).  We'd really
-- like to have GHC memoize the cracking of a known-constant format
-- string, so that it occurs at most once.
--
-- To achieve this, we arrange to have the cracked version of a format
-- string let-floated out as a CAF, by inlining the definitions of
-- build and functions that invoke it.  This works well with GHC 7.

-- | Render a format string and arguments to a 'Builder'.
build :: Params ps => Format -> ps -> Builder
build fmt ps = zipParams (crack fmt) (buildParams ps)
{-# INLINE build #-}

zipParams :: [Builder] -> [Builder] -> Builder
zipParams fragments params = go fragments params
  where go (f:fs) (y:ys) = f <> y <> go fs ys
        go [f] []        = f
        go _ _ = error . LT.unpack $ format
                 "Data.Text.Format.build: {} sites, but {} parameters"
                 (length fragments - 1, length params)

crack :: Format -> [Builder]
crack = map fromText . ST.splitOn "{}" . fromFormat

-- | Render a format string and arguments to a 'LT.Text'.
format :: Params ps => Format -> ps -> LT.Text
format fmt ps = toLazyText $ build fmt ps
{-# INLINE format #-}

-- | Render a format string and arguments, then print the result.
print :: (MonadIO m, Params ps) => Format -> ps -> m ()
print fmt ps = liftIO . LT.putStr . toLazyText $ build fmt ps
{-# INLINE print #-}

-- | Render a format string and arguments, then print the result to
-- the given file handle.
hprint :: (MonadIO m, Params ps) => Handle -> Format -> ps -> m ()
hprint h fmt ps = liftIO . LT.hPutStr h . toLazyText $ build fmt ps
{-# INLINE hprint #-}

-- | Pad the left hand side of a string until it reaches @k@
-- characters wide, if necessary filling with character @c@.
left :: B.Buildable a => Int -> Char -> a -> Builder
left k c =
    fromLazyText . LT.justifyRight (fromIntegral k) c . toLazyText . B.build

-- | Pad the right hand side of a string until it reaches @k@
-- characters wide, if necessary filling with character @c@.
right :: B.Buildable a => Int -> Char -> a -> Builder
right k c =
    fromLazyText . LT.justifyLeft (fromIntegral k) c . toLazyText . B.build

-- | Render an integer using hexadecimal notation.  (No leading "0x"
-- is added.)
hex :: Integral a => a -> Builder
hex = B.build . Hex
{-# INLINE hex #-}
