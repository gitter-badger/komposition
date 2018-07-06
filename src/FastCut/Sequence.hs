{-# OPTIONS_GHC -fno-warn-unticked-promoted-constructors #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE LambdaCase            #-}
{-# LANGUAGE OverloadedLabels      #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE StandaloneDeriving    #-}
{-# LANGUAGE TypeFamilies          #-}
module FastCut.Sequence where

import           FastCut.Prelude

import           Data.Foldable   (foldl')
import           Data.Text       (Text)
import           Data.Time.Clock (NominalDiffTime)

type Duration = NominalDiffTime

data ClipMetadata = ClipMetadata
  { clipName :: Text
  , path     :: FilePath
  , duration :: Duration
  } deriving (Eq, Show)

data MediaType = Video | Audio
  deriving (Eq, Show)

data SMediaType (mt :: MediaType) where
  SVideo :: SMediaType Video
  SAudio :: SMediaType Audio

type family InverseMediaType (t :: MediaType) :: MediaType where
  InverseMediaType Video = Audio
  InverseMediaType Audio = Video

data Clip a (mt :: MediaType)  where
  VideoClip :: a -> ClipMetadata -> Clip a Video
  AudioClip :: a -> ClipMetadata -> Clip a Audio

deriving instance Eq a => Eq (Clip a t)
deriving instance Show a => Show (Clip a t)

setClipAnnotation :: a -> Clip b t -> Clip a t
setClipAnnotation a = \case
  VideoClip _ m -> VideoClip a m
  AudioClip _ m -> AudioClip a m

data SequencePart a (mt :: MediaType) where
  Clip :: Clip a mt -> SequencePart a mt
  Gap :: a -> Duration -> SequencePart a mt

deriving instance Eq a => Eq (SequencePart a t)
deriving instance Show a => Show (SequencePart a t)

setPartAnnotation :: a -> SequencePart b t -> SequencePart a t
setPartAnnotation a = \case
  Clip (VideoClip _ m) -> Clip (VideoClip a m)
  Clip (AudioClip _ m) -> Clip (AudioClip a m)
  Gap _ d -> Gap a d

class HasDuration t where
  durationOf :: t -> Duration

instance HasDuration (Clip a t) where
  durationOf = \case
    VideoClip _ m -> duration m
    AudioClip _ m -> duration m

instance HasDuration (SequencePart a t) where
  durationOf = \case
    Clip c -> durationOf c
    Gap _ d -> d

instance HasDuration t => HasDuration [t] where
  durationOf = foldl' (\acc c -> acc + durationOf c) 0

data Sequence a
  = Sequence a [Sequence a]
  | Composition a [SequencePart a Video] [SequencePart a Audio]
  deriving (Eq, Show)

single :: Clip () t -> Sequence ()
single c = case c of
  VideoClip{} -> Composition () [Clip c] []
  AudioClip{} -> Composition () [] [Clip c]

instance Semigroup (Sequence ()) where
  Sequence _ s1 <> Sequence _ s2 = Sequence () (s1 <> s2)
  Sequence _ s1 <> s2 = Sequence () (s1 <> [s2])
  s1 <> Sequence _ s2 = Sequence () (s1 : s2)
  s1 <> s2 = Sequence () [s1, s2]

instance Monoid (Sequence ()) where
  mempty = Sequence mempty []
  mappend = (<>)
