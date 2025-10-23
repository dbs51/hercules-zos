object F_VSAM: TF_VSAM
  Left = 0
  Top = 0
  Width = 1363
  Height = 743
  Caption = 'VSAM DATASETS IN VOL '
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 1347
    Height = 684
    Align = alClient
    Color = clBlack
    DataSource = DS_VSAM
    FixedColor = clBlack
    Font.Charset = ANSI_CHARSET
    Font.Color = clLime
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    Options = [dgTitles, dgColumnResize, dgColLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWhite
    TitleFont.Height = -13
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnCellClick = DBGrid1CellClick
    OnKeyDown = DBGrid1KeyDown
    OnKeyUp = DBGrid1KeyUp
    OnTitleClick = DBGrid1TitleClick
    Columns = <
      item
        Expanded = False
        FieldName = 'Num'
        Title.Caption = 'seq'
        Width = 30
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Name'
        Title.Caption = 'name'
        Width = 268
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'T'
        Title.Alignment = taRightJustify
        Title.Caption = 'type'
        Width = 34
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Rec_Tot'
        Font.Charset = ANSI_CHARSET
        Font.Color = clFuchsia
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        Title.Alignment = taRightJustify
        Title.Caption = 'rec_tot'
        Width = 52
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Perc'
        Title.Alignment = taRightJustify
        Title.Caption = 'perc'
        Width = 42
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'MaxRecl'
        Title.Alignment = taRightJustify
        Title.Caption = 'maxrecl'
        Width = 59
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CiSize'
        Title.Alignment = taRightJustify
        Title.Caption = 'cisize'
        Width = 43
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CI_CA'
        Title.Alignment = taRightJustify
        Title.Caption = 'ci+ca'
        Width = 46
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Trk_CI'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clFuchsia
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taRightJustify
        Title.Caption = 'trk_ci'
        Width = 42
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KeyL'
        Title.Alignment = taRightJustify
        Title.Caption = 'keyl'
        Width = 35
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'RPK'
        Title.Alignment = taRightJustify
        Title.Caption = 'rpk'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Ix_Lev'
        Title.Alignment = taRightJustify
        Title.Caption = 'ix_lev'
        Width = 51
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IX_Ofs'
        Title.Alignment = taRightJustify
        Title.Caption = 'ix_ofs'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Rec_Del'
        Title.Alignment = taRightJustify
        Title.Caption = 'rec_del'
        Width = 56
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Rec_Ins'
        Title.Alignment = taRightJustify
        Title.Caption = 'rec_ins'
        Width = 65
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Rec_Upd'
        Title.Alignment = taRightJustify
        Title.Caption = 'rec_upd'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Rec_Retr'
        Title.Alignment = taRightJustify
        Title.Caption = 'rec_retr'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Alloc'
        Title.Alignment = taRightJustify
        Title.Caption = 'alloc'
        Width = 57
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Pri_SP'
        Title.Alignment = taRightJustify
        Title.Caption = 'prim_sp'
        Width = 55
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Sec_SP'
        Title.Alignment = taRightJustify
        Title.Caption = 'sec_sp'
        Width = 50
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Create'
        Title.Alignment = taRightJustify
        Title.Caption = 'created'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Excp'
        Title.Alignment = taRightJustify
        Title.Caption = 'excp'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Extents'
        Title.Alignment = taRightJustify
        Title.Caption = 'extent'
        Width = 57
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'H_URBA'
        Title.Alignment = taRightJustify
        Title.Caption = 'h_urba'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'H_ARBA'
        Title.Alignment = taRightJustify
        Title.Caption = 'h_arba'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Base'
        Title.Caption = 'base'
        Visible = True
      end>
  end
  object MainMenu1: TMainMenu
    Left = 312
    Top = 216
    object Option1: TMenuItem
      Caption = 'Option'
      object Onlywithrecs1: TMenuItem
        AutoCheck = True
        Caption = 'Only with recs'
        RadioItem = True
        OnClick = Onlywithrecs1Click
      end
    end
  end
  object DS_VSAM: TDataSource
    Left = 392
    Top = 120
  end
end
