unit bDebug;



interface

uses windows,SysUtils ;


type

  TDebugPerformanceCount=class

    tekst:string;
    startTime64,endTime64,frequency64,StartTotaalTime64,eindTotaalTime64:Int64;
    elapsedSeconds:single;

   procedure StopStart(ref:string);
   procedure Start;
   constructor Create( );
   procedure Clear;
   Function resultaat:string;

  end;


var
 aDebugPerformanceCount:TDebugPerformanceCount;


implementation

//----------

{ TDebugPerformanceCount }

procedure TDebugPerformanceCount.Clear;
begin
  tekst:='';
end;

constructor TDebugPerformanceCount.Create;
begin
  QueryPerformanceFrequency(frequency64);
  QueryPerformanceCounter(startTime64);
  tekst:='';
end;

function TDebugPerformanceCount.resultaat: string;
begin

  QueryPerformanceCounter(eindTotaalTime64);
  result:=tekst+chr(13)+chr(10);
  result:=result+FloatToStr(round((eindTotaalTime64 - StartTotaalTime64) / frequency64*1000))+ ' millisec totaal'+chr(13)+chr(10);
end;

procedure TDebugPerformanceCount.Start;
begin
  QueryPerformanceCounter(startTime64);
  StartTotaalTime64:=startTime64;
end;

procedure TDebugPerformanceCount.StopStart(ref:string);
begin
  QueryPerformanceCounter(endTime64);
  elapsedSeconds := (endTime64 - startTime64) / frequency64;
  tekst:=tekst+FloatToStr(round(elapsedSeconds*1000))+ ' millisec ref:'+ref+chr(13)+chr(10);
  QueryPerformanceCounter(startTime64);
end;

initialization

  aDebugPerformanceCount:=TDebugPerformanceCount.create;

end.
