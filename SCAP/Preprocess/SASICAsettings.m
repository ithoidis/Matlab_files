function def=SASICAsettings

def.autocorr.enable = true;
def.autocorr.dropautocorr = 0.3;
def.autocorr.autocorrint = 20;% will compute autocorrelation with this many milliseconds lag

def.focalcomp.enable = true;
def.focalcomp.focalICAout = 5;

def.trialfoc.enable = true;
def.trialfoc.focaltrialout = 8;

def.resvar.enable = false;
def.resvar.thresh = 15;% %residual variance allowed

def.SNR.enable = true;
def.SNR.snrPOI = [0 800];% period of interest (signal)
def.SNR.snrBL = [-3500 -3100];% period of no interest (noise)
def.SNR.snrcut = 1;% SNR below this threshold will be dropped

def.EOGcorr.enable = false;
def.EOGcorr.corthreshV = 'auto 4';% threshold correlation with vertical EOG
def.EOGcorr.Veogchannames = [];% vertical channel(s)
def.EOGcorr.corthreshH = 'auto 4';% threshold correlation with horizontal EOG
def.EOGcorr.Heogchannames = [];% horizontal channel(s)

def.chancorr.enable = false;
def.chancorr.corthresh = 'auto 4';% threshold correlation
def.chancorr.channames = [];% channel(s)

def.FASTER.enable = false;
def.FASTER.blinkchanname = [];

def.ADJUST.enable = true;

def.MARA.enable = false;

def.opts.FontSize = 14;
def.opts.noplot = 0;
def.opts.nocompute = 0;