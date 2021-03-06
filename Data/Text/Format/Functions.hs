{-# LANGUAGE MagicHash #-}

-- |
-- Module      : Data.Text.Format.Functions
-- Copyright   : (c) 2011 MailRank, Inc.
--
-- License     : BSD-style
-- Maintainer  : bos@serpentine.com
-- Stability   : experimental
-- Portability : GHC
--
-- Useful functions and combinators.

module Data.Text.Format.Functions
    ( i2d
    ) where

import GHC.Base

-- | Unsafe conversion for decimal digits.
{-# INLINE i2d #-}
i2d :: Int -> Char
i2d (I# i#) = C# (chr# (ord# '0'# +# i#))
