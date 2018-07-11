{-# OPTIONS_GHC -fno-warn-unticked-promoted-constructors #-}
{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE GADTs             #-}
{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedStrings #-}

-- | The import view of FastCut's GTK interface.
module FastCut.UserInterface.GtkInterface.ImportView
  ( importView
  ) where

import           FastCut.Prelude                         hiding (State, on)

import           GI.Gtk.Declarative                      as Gtk

import           FastCut.UserInterface
import           FastCut.UserInterface.GtkInterface.View

importView :: IO (View ImportMode)
importView =
  viewWithEvents $ \events ->
    container
      Box
      []
      [ BoxChild True True 0 $ node Label [#label := "Import Asset"]
      , BoxChild True True 0 $
        node
          FileChooserButton
          [ on
              #selectionChanged
              (maybe (pure ()) (writeChan events . ImportFileSelected) <=<
               Gtk.fileChooserGetFilename)
          ]
      , BoxChild True True 0 $
        node
          Button
          [ #label := "Import"
          , on #clicked (const (writeChan events ImportClicked))
          ]
      ]