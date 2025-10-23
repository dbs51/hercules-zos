object F_PDSE: TF_PDSE
  Left = -1032
  Top = -6
  Width = 1040
  Height = 1296
  ActiveControl = SG
  Caption = 'F_PDSE'
  Color = clBlack
  Font.Charset = ANSI_CHARSET
  Font.Color = clLime
  Font.Height = -15
  Font.Name = 'Courier New'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnClose = FormClose
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 17
  object Label1: TLabel
    Left = 0
    Top = 0
    Width = 1024
    Height = 17
    Align = alTop
    Caption = 'Label1'
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 385
    Width = 1024
    Height = 6
    Cursor = crVSplit
    Align = alTop
    Color = clGray
    ParentColor = False
  end
  object MM: TMemo
    Left = 0
    Top = 391
    Width = 1024
    Height = 846
    Align = alClient
    Lines.Strings = (
      'MM')
    ParentColor = True
    TabOrder = 0
  end
  object SG: TStringGrid
    Left = 0
    Top = 17
    Width = 1024
    Height = 368
    Align = alTop
    FixedColor = clGray
    FixedCols = 0
    RowCount = 4
    ParentColor = True
    TabOrder = 1
    OnDblClick = SGDblClick
    OnKeyDown = SGKeyDown
    OnSelectCell = SGSelectCell
  end
  object MainMenu1: TMainMenu
    Left = 624
    Top = 232
    object SaveBin: TMenuItem
      Caption = 'Save '
      OnClick = SaveBinClick
    end
    object Quit: TMenuItem
      Caption = 'Quit'
      OnClick = QuitClick
    end
  end
end
