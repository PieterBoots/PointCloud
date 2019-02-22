object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 749
  ClientWidth = 1370
  Color = clWindow
  Ctl3D = False
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnMouseMove = Image1MouseMove
  OnMouseUp = Image1MouseUp
  OnMouseWheel = FormMouseWheel
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 136
    Top = 32
    Width = 1024
    Height = 768
    OnMouseDown = Image1MouseDown
    OnMouseMove = Image1MouseMove
    OnMouseUp = Image1MouseUp
  end
  object Label2: TLabel
    Left = 1191
    Top = 440
    Width = 31
    Height = 13
    Caption = 'Label2'
  end
  object Memo1: TMemo
    Left = 1239
    Top = 24
    Width = 290
    Height = 170
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
  end
  object ScrollBar1: TScrollBar
    Left = 8
    Top = 200
    Width = 105
    Height = 33
    Max = 30
    PageSize = 0
    Position = 1
    TabOrder = 1
  end
  object ScrollBar2: TScrollBar
    Left = 8
    Top = 255
    Width = 97
    Height = 33
    Max = 1000
    PageSize = 0
    TabOrder = 2
  end
  object Timer1: TTimer
    Interval = 5
    OnTimer = Timer1Timer
    Left = 32
    Top = 64
  end
end
