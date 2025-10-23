object F_Find: TF_Find
  Left = 101
  Top = 110
  Width = 739
  Height = 503
  Caption = 'Find dataset or text'
  Color = clWhite
  Ctl3D = False
  Font.Charset = ANSI_CHARSET
  Font.Color = clBlue
  Font.Height = -12
  Font.Name = 'Lucida Console'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 12
  object L_Msg: TLabel
    Left = 0
    Top = 153
    Width = 723
    Height = 16
    Align = alTop
    Alignment = taCenter
    Caption = 'Process'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'Lucida Console'
    Font.Style = []
    ParentColor = False
    ParentFont = False
  end
  object MM: TMemo
    Left = 0
    Top = 169
    Width = 723
    Height = 295
    Align = alClient
    BevelEdges = []
    Color = clWhite
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 0
    OnDblClick = MMDblClick
  end
  object GroupBox1: TGroupBox
    Left = 416
    Top = 56
    Width = 188
    Height = 64
    Caption = 'Limit'
    TabOrder = 1
    object Label3: TLabel
      Left = 14
      Top = 16
      Width = 35
      Height = 12
      Caption = 'Quant'
    end
    object Label6: TLabel
      Left = 15
      Top = 39
      Width = 42
      Height = 12
      Caption = 'Volume'
    end
    object Edit2: TEdit
      Left = 70
      Top = 40
      Width = 83
      Height = 14
      BevelEdges = [beBottom]
      BevelInner = bvNone
      BevelKind = bkSoft
      BorderStyle = bsNone
      Color = clWhite
      TabOrder = 0
      OnKeyDown = T_DsnPdsNameKeyDown
    end
    object Edit3: TEdit
      Left = 70
      Top = 14
      Width = 83
      Height = 14
      BevelEdges = [beBottom]
      BevelInner = bvNone
      BevelKind = bkSoft
      BorderStyle = bsNone
      Color = clWhite
      TabOrder = 1
      OnKeyDown = T_DsnPdsNameKeyDown
    end
  end
  object PC: TPageControl
    Left = 0
    Top = 0
    Width = 723
    Height = 153
    ActivePage = TS_Dsn
    Align = alTop
    RaggedRight = True
    Style = tsFlatButtons
    TabOrder = 2
    object TS_Dsn: TTabSheet
      Caption = 'Dataset'
      object Label5: TLabel
        Left = 20
        Top = 8
        Width = 147
        Height = 12
        Caption = 'Data set name filter:'
      end
      object B_FIndDSN: TButton
        Left = 16
        Top = 103
        Width = 97
        Height = 16
        Caption = 'Find dataset '
        TabOrder = 0
        OnClick = B_FindClick
      end
      object RG_DsnType: TRadioGroup
        Left = 13
        Top = 27
        Width = 476
        Height = 36
        BiDiMode = bdLeftToRight
        Caption = 'type'
        Columns = 6
        Ctl3D = True
        ItemIndex = 1
        Items.Strings = (
          'all'
          'pds'
          'ps'
          'vsam'
          'hps'
          'pdse')
        ParentBiDiMode = False
        ParentBackground = False
        ParentCtl3D = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 1
      end
      object RG_dsn_opt: TRadioGroup
        Left = 300
        Top = 0
        Width = 188
        Height = 27
        BiDiMode = bdLeftToRight
        Columns = 2
        Ctl3D = False
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ItemIndex = 0
        Items.Strings = (
          'initial     '
          'partial')
        ParentBiDiMode = False
        ParentBackground = False
        ParentCtl3D = False
        ParentFont = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 2
      end
      object E_dsn_dsn: TEdit
        Left = 180
        Top = 4
        Width = 80
        Height = 14
        Hint = 'ADCD'
        BevelEdges = [beBottom]
        BevelInner = bvNone
        BevelKind = bkSoft
        BorderStyle = bsNone
        Color = clWhite
        TabOrder = 3
        OnKeyDown = T_DsnPdsNameKeyDown
      end
      object GroupBox3: TGroupBox
        Left = 504
        Top = 0
        Width = 185
        Height = 65
        Caption = 'Limit'
        TabOrder = 4
        object Label9: TLabel
          Left = 10
          Top = 19
          Width = 35
          Height = 12
          Caption = 'Max: '
        end
        object Label10: TLabel
          Left = 10
          Top = 37
          Width = 49
          Height = 12
          Caption = 'Volume:'
        end
        object E_dsn_max: TEdit
          Left = 70
          Top = 18
          Width = 80
          Height = 14
          BevelEdges = [beBottom]
          BevelInner = bvNone
          BevelKind = bkSoft
          BorderStyle = bsNone
          Color = clWhite
          TabOrder = 0
          Text = '400'
          OnKeyDown = T_DsnPdsNameKeyDown
        end
        object E_dsn_vol: TEdit
          Left = 70
          Top = 37
          Width = 80
          Height = 14
          BevelEdges = [beBottom]
          BevelInner = bvNone
          BevelKind = bkSoft
          BorderStyle = bsNone
          Color = clWhite
          TabOrder = 1
          OnKeyDown = T_DsnPdsNameKeyDown
        end
      end
    end
    object TS_Member: TTabSheet
      Caption = 'Text member'
      ImageIndex = 2
      object Label4: TLabel
        Left = 20
        Top = 26
        Width = 98
        Height = 12
        Caption = 'Member filter:'
      end
      object Label2: TLabel
        Left = 20
        Top = 44
        Width = 105
        Height = 12
        Caption = 'Text to search:'
      end
      object Label8: TLabel
        Left = 20
        Top = 8
        Width = 147
        Height = 12
        Caption = 'Data set name filter:'
      end
      object E_mem_mem: TEdit
        Left = 180
        Top = 25
        Width = 80
        Height = 13
        BevelEdges = [beBottom]
        BevelInner = bvNone
        BevelKind = bkSoft
        BorderStyle = bsNone
        Color = clWhite
        Ctl3D = False
        ParentCtl3D = False
        TabOrder = 2
        Text = 'LIB'
        OnKeyDown = T_DsnPdsNameKeyDown
      end
      object B_FIndText: TButton
        Tag = 1
        Left = 0
        Top = 103
        Width = 113
        Height = 16
        Caption = 'Search pds text'
        TabOrder = 0
        OnClick = B_FindClick
      end
      object RG_mem_opt: TRadioGroup
        Left = 300
        Top = 0
        Width = 188
        Height = 27
        BiDiMode = bdLeftToRight
        Columns = 2
        Ctl3D = False
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ItemIndex = 0
        Items.Strings = (
          'initial     '
          'partial')
        ParentBiDiMode = False
        ParentBackground = False
        ParentCtl3D = False
        ParentFont = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 5
      end
      object E_mem_dsn: TEdit
        Left = 180
        Top = 4
        Width = 80
        Height = 14
        BevelEdges = [beBottom]
        BevelInner = bvNone
        BevelKind = bkSoft
        BorderStyle = bsNone
        Color = clWhite
        TabOrder = 1
        Text = 'SYS1'
        OnKeyDown = T_DsnPdsNameKeyDown
      end
      object E_mem_txt: TEdit
        Left = 181
        Top = 45
        Width = 80
        Height = 13
        BevelEdges = [beBottom]
        BevelInner = bvNone
        BevelKind = bkSoft
        BorderStyle = bsNone
        Color = clWhite
        Ctl3D = False
        ParentCtl3D = False
        TabOrder = 4
        Text = 'IGWPFAR'
        OnKeyDown = T_DsnPdsNameKeyDown
      end
      object GroupBox2: TGroupBox
        Left = 504
        Top = 0
        Width = 185
        Height = 65
        Caption = 'Limit'
        TabOrder = 3
        object Label1: TLabel
          Left = 10
          Top = 19
          Width = 35
          Height = 12
          Caption = 'Max: '
        end
        object Label7: TLabel
          Left = 10
          Top = 37
          Width = 49
          Height = 12
          Caption = 'Volume:'
        end
        object E_mem_max: TEdit
          Left = 70
          Top = 18
          Width = 80
          Height = 14
          BevelEdges = [beBottom]
          BevelInner = bvNone
          BevelKind = bkSoft
          BorderStyle = bsNone
          Color = clWhite
          TabOrder = 0
          Text = '400'
          OnKeyDown = T_DsnPdsNameKeyDown
        end
        object E_mem_vol: TEdit
          Left = 70
          Top = 37
          Width = 80
          Height = 14
          BevelEdges = [beBottom]
          BevelInner = bvNone
          BevelKind = bkSoft
          BorderStyle = bsNone
          Color = clWhite
          TabOrder = 1
          OnKeyDown = T_DsnPdsNameKeyDown
        end
      end
    end
  end
end
