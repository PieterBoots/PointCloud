unit Unit1;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  system.types,
  math,
  StrUtils,
  bDebug, Vcl.ExtCtrls, Vcl.StdCtrls ;

const
  MeshWidth=1024;
  MeshHeight=768;


type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MeshWidth*MeshHeight-1] of TRGBTriple;

  Tvertex =record
    x,y,z:single;
  end;

  TCloudPoint= record
    point:Tvertex;
    rpoint:Tvertex;
    c: Integer;
    normal:Tvertex;
    rnormal:Tvertex;
  end;

  Tmatrix = record
    x1,y1,z1:single;
    x2,y2,z2:single;
    x3,y3,z3:single;
  end;

  type
  TRGBTriple = packed record
    rgbtBlue: Byte;
    rgbtGreen: Byte;
    rgbtRed: Byte;
  end;

   TMouseStatus = record
    Down: boolean;
    XStart: integer;
    YStart: integer;
    XMove: integer;
    YMove: integer;
    XRotationMove: integer;
    YRotationMove: integer;
    XRotationHold: integer;
    YRotationHold: integer;
  end;

  TAngles = record
     sinx, siny, sinz: single;
     cosx, cosy, cosz: single;
  end;

  Tpointcloud =array of TCloudPoint;

  TForm1 = class(TForm)
    Memo1: TMemo;
    Timer1: TTimer;
    Image1: TImage;
    Label2: TLabel;
    ScrollBar1: TScrollBar;
    ScrollBar2: TScrollBar;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseLeave(Sender: TObject);
    procedure FormMouseLeave(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
    PointCloud:Tpointcloud;
    Angles:TAngles;
    pointsfast:array of Tvertex;
    MouseStatus:TMouseStatus;
    procedure MousePosSave;
    function SetAngles(phix, phiy, phiz: integer):TAngles;
    function Rotate(Vertex:Tvertex):Tvertex;
    procedure ReadPly(Filename:string);
    procedure RefrechWorld;
  end;

var
  rotx,roty:integer;
  cnt:integer;
  StartTime, EndTime, Delta,deltacnt: Int64;
  ImageBuffer:array[0..MeshWidth*MeshHeight-1] of integer;
  depth:array[0..MeshWidth*MeshHeight-1] of single;
  index:array[0..MeshWidth*MeshHeight-1] of integer;
  Bmp:Tbitmap;
  Form1: TForm1;

implementation

{$R *.dfm}

//----------------------
procedure TForm1.ReadPly(Filename:string);
var
  myFile : TextFile;
  text,newline:string;
  cntV:integer;
  StartReadingPoints:Boolean;

//---
function GetPoint(S:String) : Tcloudpoint;
var
  cloudpoint:TCloudPoint;
  tmp:string;
  tsl: TStringList;
begin
  tmp:=AnsiReplaceStr(s,' ',',');
  tsl := TStringList.Create;
  tsl.CommaText := tmp;
  if   tsl.Count=10 then
  begin
    cloudpoint.point.x :=StrToFloat(tsl.Strings[0])/50;
    cloudpoint.point.y :=StrToFloat(tsl.Strings[1])/50;
    cloudpoint.point.z :=StrToFloat(tsl.Strings[2])/50;
    cloudpoint.c :=StrToInt(tsl.Strings[3])+StrToInt(tsl.Strings[4])*256+StrToInt(tsl.Strings[5])*65536;
    cloudpoint.normal.x :=StrToFloat(tsl.Strings[6]);
    cloudpoint.normal.y :=StrToFloat(tsl.Strings[7]);
    cloudpoint.normal.z :=StrToFloat(tsl.Strings[8]);
  end
  else
  begin
    ShowMessage(s);
  end;
  tsl.Free;
  Result :=cloudpoint;
end;

//----------------------

begin
 FormatSettings.DecimalSeparator := '.';
 AssignFile(myFile,Filename);
 Reset(myFile);
 cntV:=0;
 StartReadingPoints:=false;
  while not Eof(myFile) do
   begin
     ReadLn(myFile, text);
     if AnsiContainsStr(text,'element vertex')=true then
     begin
       newline:=trim(AnsiReplaceStr(text,'element vertex',''));
       SetLength(PointCloud,Ceil(StrToInt(newline)/4)*4 );
     end;
     if StartReadingPoints=true then
     begin
      PointCloud[cntV]:=GetPoint(text);
      cntV:=cntV+1;
     end;
     if AnsiContainsStr(text,'end_header')=true then
     begin
       StartReadingPoints:=true;
     end;
   end;
end;
 //----------------------
procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
  avgx,avgy,avgz:single;
  cloudpoint:TCloudPoint;
begin
  ReadPly('12224_Cat_v5_l3.ply');
  angles:=SetAngles(-180,0, 0);
  avgx:=0 ;
  avgy:=0  ;
  avgz:=0;
  setlength(pointsfast  ,length(pointcloud));
  for i:=length(pointcloud)-1 downto  0 do
  begin
     cloudpoint:=pointcloud[i];
     cloudpoint.point:=rotate(cloudpoint.point);
     pointcloud[i]:=cloudpoint;
     avgx:=avgx+cloudpoint.point.x ;
     avgy:=avgy+cloudpoint.point.y ;
     avgz:=avgz+cloudpoint.point.z ;
  end;
    for i:=length(pointcloud)-1 downto  0 do
  begin
     cloudpoint:=pointcloud[i];
     cloudpoint.point.x:=cloudpoint.point.x-avgx/length(pointcloud);
     cloudpoint.point.y:=cloudpoint.point.y-avgy/length(pointcloud);
     cloudpoint.point.z:=cloudpoint.point.z-avgz/length(pointcloud);
     pointsfast[i].x:= cloudpoint.point.x;
     pointsfast[i].y:=cloudpoint.point.y;
     pointsfast[i].z:=cloudpoint.point.z;
     pointcloud[i]:=cloudpoint;
  end;
  RefrechWorld;
  Bmp:=Tbitmap.Create;
  Bmp.Width:=MeshWidth;
  Bmp.Height:=MeshHeight;
  Bmp.PixelFormat := pf24bit;
end;
 //----------------------
procedure TForm1.FormMouseLeave(Sender: TObject);
begin
 MousePosSave;
end;
 //----------------------
procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 ScrollBar2.Position:=ScrollBar2.Position+WheelDelta div 60;
end;
  //----------------------
procedure TForm1.MousePosSave;
begin
  if MouseStatus.Down = true then
  begin
    with MouseStatus do
    begin
      Down := false;
      XRotationHold := XRotationHold + (XMove - XStart);
      YRotationHold := YRotationHold + (YMove - YStart);
      XRotationMove := XRotationHold;
      YRotationMove := YRotationHold;
    end;
  end;
end;
 //----------------------
procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Screenpoint:Tpoint;
begin
  Screenpoint := Mouse.CursorPos;
  MouseStatus.XStart := Screenpoint.x;
  MouseStatus.yStart := Screenpoint.y;

  if button = mbleft then
  begin
    MouseStatus.Down := true;
  end;
end;
//----------------------
procedure TForm1.Image1MouseLeave(Sender: TObject);
begin
 MousePosSave;
end;
//----------------------
procedure Tform1.RefrechWorld;
var
  i:integer;
  y1,z1:single;
  cloudpoint:TCloudPoint;
begin
  angles:=SetAngles(360 + MouseStatus.YRotationMove div 2, MouseStatus.XRotationMove div 2, 0);
  for i:=0 to length(PointCloud)-1 do
  begin
    cloudpoint:=PointCloud[i];
    y1 := cloudpoint.point.y;
    z1 := cloudpoint.point.z * Angles.cosy   - cloudpoint.point.x * Angles.siny  ;
    cloudpoint.rpoint.x := cloudpoint.point.x * Angles.cosy  + cloudpoint.point.z * Angles.siny;
    cloudpoint.rpoint.y := y1 * Angles.cosx  - z1 * Angles.sinx  ;
    cloudpoint.rpoint.z := y1 * Angles.sinx   + z1 * Angles.cosx  ;
    PointCloud[i]:=cloudpoint;
  end;
   aDebugPerformanceCount.StopStart('rotate');
   aDebugPerformanceCount.StopStart('sort');
end;
//----------------------
procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  Screenpoint: Tpoint;
begin
  if MouseStatus.Down = true then
  begin
    Screenpoint := Mouse.CursorPos;
    MouseStatus.XMove := Screenpoint.x;
    MouseStatus.yMove := Screenpoint.y;
    MouseStatus.XRotationMove := MouseStatus.XRotationHold + (MouseStatus.XMove - MouseStatus.XStart);
    MouseStatus.YRotationMove := MouseStatus.YRotationHold + (MouseStatus.YMove - MouseStatus.YStart);

    if MouseStatus.yRotationMove < -40 then
    begin
      MouseStatus.YRotationMove := -40;
      MouseStatus.YRotationHold := -40;
      MouseStatus.YStart := Screenpoint.y;
    end;
    //
    if MouseStatus.yRotationMove > 420 then
    begin
      MouseStatus.yRotationMove := 420;
      MouseStatus.YRotationHold := 420;
      MouseStatus.YStart := Screenpoint.y;
    end;
  end;
end;
 //----------------------
procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MousePosSave;
end;
//----------------------
procedure TForm1.Timer1Timer(Sender: TObject);
begin
  button1click(sender);
end;
//----------------------
procedure TForm1.Button1Click(Sender: TObject);
var
  i,j,l,xx,yy:integer;
  x,y,z,x1,y1,z1:single;
  r,g,b:integer;
  faceNo:integer;
  shadeValue,pos:integer;
  vec2,vec3,vec4:TVertex;
  vec1:^TVertex;
  vec:TVertex;
  point1,point2,point3,point4:Tpoint;
  cloudpoint:TCloudPoint;
  Pixels: PRGBTripleArray;
  color:integer;
  Scale,Ypart:integer;
  dist:integer;
  matrix:Tmatrix;
  parts:single;
  ofs,c:integer;
  circle:array[0..5000] of integer;
  cmin,cmax:array[-100..100] of integer;
  eindcir:integer;
  miny,maxy:integer;

Function RoundSSE(Value: Single): Integer; Overload;
Asm
  // additional PUSH/POP pointer stack added automatically
  CVTSS2SI  EAX, Value
End;

begin
  aDebugPerformanceCount.Start;
  aDebugPerformanceCount.Clear;

  yy:=ScrollBar1.Position;//RoundSSE(0.001*parts/(1+z));
  i:=0;
  miny:=99999;
  maxy:=0;
  for l:=-yy-2 to yy+2 do
    begin
      cmin[l]:=999;
      cmax[l]:=-999;
      for j:=-yy-2 to yy+2 do
      begin
        dist:=round(sqrt(l*l+j*j));
        pos:= (l)*MeshWidth+(j);
        if (dist<=yy) then
        begin
           if l<miny then miny:=l;
           if l>maxy then maxy:=l;
           if j<cmin[l] then cmin[l]:= (l)*MeshWidth+(j);
           if j>cmax[l] then cmax[l]:= (l)*MeshWidth+(j);
           circle[i]:=pos;
           i:=i+1;
        end;
      end;
    end;
    eindcir:=i-1;

//  RefrechWorld;
  angles:=SetAngles(360 + MouseStatus.YRotationMove div 2, MouseStatus.XRotationMove div 2, 0);

  for i:=0 to length(ImageBuffer)-1 do
  begin
    imageBuffer[i]:=0;
    Depth[i]:=99999;
    index[i]:=-1;
  end;

   Scale:=image1.Width;
  if image1.Height<Scale then Scale:=image1.Height;

  parts:= scale*150 *ScrollBar2.Position/5000 ;

  matrix.x1:=Angles.cosy*parts;
  matrix.x2:=Angles.siny  * Angles.sinx*parts ;
  matrix.x3:=(- Angles.siny * Angles.cosx );

  matrix.y1:=0*parts;
  matrix.y2:=Angles.cosx*parts ;
  matrix.y3:=Angles.sinx;

  matrix.z1:= Angles.siny*parts;
  matrix.z2:= (- Angles.cosy * Angles.sinx) *parts;
  matrix.z3:= Angles.cosy  * Angles.cosx;
  aDebugPerformanceCount.StopStart('clear');
  ofs:=(image1.height div 2)*MeshWidth+(image1.Width  div 2);
   i:=length(pointcloud)-1;

   repeat
      //rotate
     vec1:=@pointsfast[i];
     x := vec1.x * matrix.x1 + vec1.y *  matrix.y1  + vec1.z * matrix.z1 ;
     y := vec1.x * matrix.x2 + vec1.y *  matrix.y2  + vec1.z * matrix.z2 ;
     z := 1+vec1.x * matrix.x3 + vec1.y *  matrix.y3  + vec1.z * matrix.z3 ;
      //project
     xx:=RoundSSE(x/z);
     yy:=RoundSSE(y/z);
     if (xx>-511) and (xx<511) and (yy>-383) and (yy<383) then
     begin
       pos:=ofs+(yy)*MeshWidth+xx;
       if z<depth[pos] then
       begin
          Depth[pos]:= z;
          index[pos]:=i;
       end;
     end;
     dec(i);
   until i=-1;

   aDebugPerformanceCount.StopStart('project');

  for i:=0 to length(ImageBuffer)-1 do
  begin
    if (index[i]>-1) then
    begin
      vec1:=@pointsfast[index[i]];
      z := vec1.x * matrix.x3 + vec1.y *  matrix.y3  + vec1.z * matrix.z3 ;
      point1.X:=i mod 1024;
      point1.Y:=i div 1024;
      if (point1.X>ScrollBar1.Position) and (point1.X<1023-ScrollBar1.Position) and (point1.Y>ScrollBar1.Position) and (point1.Y<767-ScrollBar1.Position) then
      begin
       c:=pointcloud[index[i]].c;
      for j:=0 to eindcir do
        begin
        pos:= circle[j]+i;
            if z<=depth[pos] then
            begin
               ImageBuffer[pos]:=c;
               Depth[pos]:= z;
            end;
        end;
      end;
    end;
  end;
   aDebugPerformanceCount.StopStart('buffer');

   for j:=0 to bmp.height-1 do
    begin
      Pixels := bmp.ScanLine[j];
      for I := 0 to bmp.Width - 1 do
      begin
        color:=ImageBuffer[j*MeshWidth+i];
        Pixels[I].rgbtBlue :=  (color shr 16);
        Pixels[I].rgbtGreen := (color shr 8 and (255) );
        Pixels[I].rgbtRed :=(color and 255);
      end;
    end;
    image1.Canvas.Draw(0,0,bmp);
    aDebugPerformanceCount.StopStart('draw');
    memo1.Text:=aDebugPerformanceCount.tekst;
end;
//----------------------
function TForm1.SetAngles(phix, phiy, phiz: integer):TAngles;
begin
  result.sinx := sin(phix * PI / 360);
  result.cosx := Cos(phix * PI / 360);
  result.siny := sin(phiy * PI / 360);
  result.cosy := Cos(phiy * PI / 360);
  result.sinz := sin(phiz * PI / 360);
  result.cosz := Cos(phiz * PI / 360);
end;
//----------------------
function Tform1.Rotate(Vertex:Tvertex):Tvertex;
var
  x1, y1, z1: single;
begin
  x1 := vertex.x * Angles.cosy  + vertex.z * Angles.siny  ;
  y1 := vertex.y;
  z1 := vertex.z * Angles.cosy   - vertex.x * Angles.siny  ;
  result.x := x1;
  result.y := y1 * Angles.cosx  - z1 * Angles.sinx  ;
  result.z := y1 * Angles.sinx   + z1 * Angles.cosx  ;
end;
//----------------------

end.
