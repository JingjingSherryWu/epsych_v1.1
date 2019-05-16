function varargout = ep_GenericPlot(varargin)
% EP_GENERICPLOT MATLAB code for ep_GenericPlot.fig
%      EP_GENERICPLOT, by itself, creates a new EP_GENERICPLOT or raises the existing
%      singleton*.
%
%      H = EP_GENERICPLOT returns the handle to a new EP_GENERICPLOT or the handle to
%      the existing singleton*.
%
%      EP_GENERICPLOT('CALLBACK',hObj,event,h,...) calls the local
%      function named CALLBACK in EP_GENERICPLOT.M with the given input arguments.
%
%      EP_GENERICPLOT('Property','Value',...) creates a new EP_GENERICPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ep_GenericPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ep_GenericPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ep_GenericPlot

% Last Modified by GUIDE v2.5 09-May-2019 13:35:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_GenericPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_GenericPlot_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ep_GenericPlot is made visible.
function ep_GenericPlot_OpeningFcn(hObj, event, h, varargin)
% Choose default command line output for ep_GenericPlot
h.output = hObj;

% Update h structure
guidata(hObj, h);


% --- Outputs from this function are returned to the command line.
function varargout = ep_GenericPlot_OutputFcn(hObj, event, h) 
varargout{1} = h.output;


h.GTIMER = ep_GenericGUITimer(h.ep_GenericPlot);
h.GTIMER.TimerFcn = @runtime_plot;
h.GTIMER.StartFcn = @setup_gui;

start(h.GTIMER);

sot = getpref('ep_GenericPlot','stayOnTop',false);
h.stayOnTop.Value = sot;
stay_on_top(h.stayOnTop);




function setup_gui(~,~,f)
global RUNTIME

h = guidata(f);

fn = fieldnames(RUNTIME.TRIALS.DATA);

T = RUNTIME.TRIALS.trials;


% Setup X and Y lists for plotting

% for the x variable, use a default value with the largest number of unique
% values
n = zeros(size(T,1),1);
for i = 1:size(T,2)
    try %#ok<TRYNC>
        n(i) = length(unique([T{:,i}]));
    end
end
[~,i] = max(n);
% x = fn{i(1)};
set(h.list_x_variable, ...
    'String',fn, ...
    'Value',i(1), ...
    'TooltipString','Select one X parameter');

set(h.list_y_variable, ...
    'String',[{'< HIT-/FA-RATE >'; '< D-PRIME >'}; fn], ...
    'Value',1, ...
    'TooltipString','Select a Y parameter');

cla(h.mainAxes);

grid(h.mainAxes,'on');
box(h.mainAxes,'on');

h.lineH = line(h.mainAxes,nan,nan,'linewidth',2,'marker','o','color',[0 0 0]);


function runtime_plot(timerObj,~,f)
% TO DO: Make TrialType integer and ResponseCode bits user defineable
% for now, ResponseCode bit: Hit = 3; Miss = 4; CR = 6; FA = 7
global RUNTIME PRGMSTATE

% persistent variables hold their values across calls to this function
persistent lastupdate

% stop if the program state has changed
if ismember(PRGMSTATE,{'ERROR','STOP'}), stop(timerObj); return; end

% number of trials is length of
ntrials = RUNTIME.TRIALS.DATA(end).TrialID;

if isempty(ntrials)
    ntrials = 0;
    lastupdate = 0;
end

    
% escape timer function until a trial has finished
if ntrials == lastupdate,  return; end
lastupdate = ntrials;
% `````````````````````````````````````````````````````````````````````````

h = guidata(f);

DATA = RUNTIME.TRIALS.DATA;
if isempty(DATA(end).ResponseCode), return; end

% TrialType    = [DATA.TrialType];
ResponseCode = [DATA.ResponseCode];

% make this user definable (or even loaded from a *.epdp file?)
Hit   = bitget(ResponseCode,3);
Miss  = bitget(ResponseCode,4);
CR    = bitget(ResponseCode,6);
FA    = bitget(ResponseCode,7);

xVar = h.list_x_variable.String{h.list_x_variable.Value};
yVar = h.list_y_variable.String{h.list_y_variable.Value};

x = [DATA.(xVar)];
ux = unique(x);
n = length(ux);

nHits(n,1) = 0; nMiss = nHits; nCR = nHits; nFA = nHits;
for i = 1:n
    ind = x == ux(i);
    nHits(i) = sum(Hit(ind));
    nMiss(i) = sum(Miss(ind));
    nCR(i)   = sum(CR(ind));
    nFA(i)   = sum(FA(ind));
end

HitRate = nHits./(nHits+nMiss);
FARate  = nFA./(nFA+nCR);

% y may be calculated using he Response Code
switch yVar
    case '< HIT-/FA-RATE >'
        y = HitRate-FARate;
        
    case '< D-PRIME >'
        y = dprime(HitRate,FARate);
        
    otherwise
        y = [DATA.(yVar)];
end

x = repmat(x(:),1,size(y,2));

h.lineH.XData = x;
h.lineH.YData = y;
drawnow
