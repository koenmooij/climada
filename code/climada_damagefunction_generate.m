function [damagefunction,dmf_info_str]=climada_damagefunction_generate(intensity,dmf_min_intens,dmf_exp,dmf_max,dmf_shape,peril_ID,check_plot)
% climada template
% MODULE:
%   core
% NAME:
%   climada_damagefunction_generate
% PURPOSE:
%   Generate damagefunction
%
%   See also: climada_damagefunction_map and _plot ...
% CALLING SEQUENCE:
%   damagefunction=climada_damagefunction_generate(intensity,dmf_min_intens,dmf_exp,dmf_max,dmf_shape,peril_ID,check_plot)
% EXAMPLE:
%   damagefunction=climada_damagefunction_generate(0:10:120,20,3,1,'exp','TC')
%   damagefunction=climada_damagefunction_generate([],20,1,0.5,'s-shape','TC',1)
% INPUTS:
%   intensity: the hazard intensity scale, i.e. the horizontal axis of the
%       damage function. Any vector of intensities, acending in value,
%       such as 1:10:100
%   dmf_min_intens: minimum intensity for MDD and PPA >0, default=0
%   dmf_exp: the exponent of the damage function, see also shape
%   dmf_max: the maximum value of MDD (and PAA), default=1
%   dmf_shape: the shape of the damage function, implemented are (the
%   damagefunction are always normalized such that MDD(max intensity=1):
%       'exp' for expoential shape, i.e.
%       MDD=(intensity-dmf_min_intens)^dmf_exp
%       's-shape' for an S-shaped damage function, satrting a
%       dmf_min_intens and 'skewed by dmf_exp
%   peril_ID: the 2-digit peril_ID, such as 'TC','EQ',...
% OPTIONAL INPUT PARAMETERS:
%   check_plot: =1 to show a check plot (using
%       climada_damagefunction_plot) or not (=0, default)
%       plots on the same plot on sunsequent calls to allow for easy
%       comparison of say two options
% OUTPUTS:
%   damagefunction: a structure with
%       filename: just for information, here 'climada_damagefunction_generate'
%       Intensity(i): the hazard intensity (a vector)
%       DamageFunID(i): =ones(1,length(Intensity)
%       peril_ID{i}: a cell array with peril_ID
%       MDD(i): the mean damage degree value for Intensity(i)
%       PAA(i): the percentage of affected assets for Intensity(i)
%   dmf_info_str: the parameters returned as a string (e.g. for annotation),
%       in the form 'shape dmf_max*(i-dmf_min_intens)^dmf_exp'
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150211, initial
%-

damagefunction=[]; % init output
dmf_info_str=''; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('intensity','var'),intensity=[];end
if ~exist('dmf_min_intens','var'),dmf_min_intens=[];end
if ~exist('dmf_exp','var'),dmf_exp=[];end
if ~exist('dmf_max','var'),dmf_max=[];end
if ~exist('dmf_shape','var'),dmf_shape='';end
if ~exist('peril_ID','var'),peril_ID='';end
if ~exist('check_plot','var'),check_plot=[];end

% PARAMETERS
%
% define all default parameters
if isempty(intensity),intensity=0:10:120;end
if isempty(dmf_min_intens),dmf_min_intens=20;end
if isempty(dmf_exp),dmf_exp=3;end
if isempty(dmf_max),dmf_max=1;end
if isempty(dmf_shape),dmf_shape='exp';end
if isempty(peril_ID),peril_ID='TC';end
if isempty(check_plot),check_plot=1;end


dmf_info_str=sprintf('%s %s %3.3f*(i-%i)**%2.2f',peril_ID,dmf_shape,dmf_max,dmf_min_intens,dmf_exp);

if size(intensity,1)<size(intensity,2),intensity=intensity';end

damagefunction.filename=mfilename;
damagefunction.Intensity=intensity;
damagefunction.DamageFunID=damagefunction.Intensity*0+1;
damagefunction.peril_ID=cellstr(repmat(peril_ID,length(damagefunction.Intensity),1));

switch dmf_shape
    case 'exp'
        % polynomial damage function
        damagefunction.MDD=max(damagefunction.Intensity-dmf_min_intens,0).^dmf_exp;
        damagefunction.MDD=dmf_max*damagefunction.MDD/damagefunction.MDD(end);
        damagefunction.PAA=max(damagefunction.Intensity-dmf_min_intens,0).^dmf_exp;
        damagefunction.PAA=damagefunction.PAA/damagefunction.PAA(end);
    case 's-shape'
        % S-shaped damage function
        damagefunction.MDD=damagefunction.Intensity*0; % init
        damagefunction.PAA=damagefunction.Intensity*0; % init
        Intensity_pos=damagefunction.Intensity>dmf_min_intens;
        n_x=sum(Intensity_pos);
        x = -2:4/n_x:2;y = erf(x);y=y-y(1);y=y/max(y); % erf to get S-shape
        damagefunction.MDD(Intensity_pos)=y(1:end-1);
        damagefunction.PAA(Intensity_pos)=y(1:end-1);
        damagefunction.MDD=dmf_max*(damagefunction.MDD.^dmf_exp);
        damagefunction.PAA=(damagefunction.PAA.^dmf_exp);
    otherwise
        fprintf('Error: %s not implemented yet\n',dmf_shape)
        return
end % switch dmf_shape

if check_plot,climada_damagefunctions_plot(damagefunction);end

end % climada_damagefunction_generate