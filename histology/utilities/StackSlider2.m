
% modified JF: brightness / contrast, two images
% to do:
% get smoothing to work
% colormap
% contrast selection (in a fast way) 
%
% StackSlider(varargin): GUI for displaying images from, e.g., an lsm stack
% or other 3D array. Can be called in several ways:
%
% StackSlider() without input lets the user choose an lsm file to be
% displayed. Images will be converted to and shown on an 8-bit scale.
%
% StackSlider(I) where I is a 3D array will display the array, assuming that
% consecutive images are arrayed along the third dimension. As above, uses
% 8-bit colors.
%
% StackSlider('filename') where filename is a path and name of a valid image
% stack will display said stack. As above, uses 8-bit colors.
%
% StackSlider(X,'type') where X is _either_ an array or filename as above
% will convert the input array to the class 'type' (uint8 or uint16) and
% display it. Note: StackSlider will not convert an 8-bit image to a 16-bit,
% since this is plain stupid.
%
% The GUI itself lets the user scroll back and forth among the frames using a
% slider, och jump to a frame by writing the frame number in an editbox.
% The colormap can be chosen from a popup menu.
% 
% Smoothing can be chosen as "no smoothing" (displays the raw data), "Gaussian"
% (user can set radius of filter and standard deviation of filter) and 
% "averaging" (moving average over a disk of user-controlled radius).
% NOTE: The size of the gaussian filter is the radius, and not the diameter 
% set when using, e.g., fspecial and imfilter.
%
% The "reset all" button does exactly that.
%
% The "make figure" button makes a new figure of the currently shown frame,
% using the selected smoothing options. Note that the new figure does not
% inherit the colormap limits, but is streched over the colormap using "imagesc".
%
% This program calls tiffread.m, which can be downloaded for free from
% http://www.cytosim.org/other/
%
% Written by Otto Manneberg, SciLifeLab 2011-07-22.
% otto.manneberg@scilifelab.se
% Copyright (c) 2011, Otto Manneberg
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of the Science for Life Laboratory (SciLifeLab) nor the
%       names of its contributors may be used to endorse or promote products
%       derived from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function [] = bc_ StackSlider2(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input argument checking and handling                                   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin > 3
    disp('Error in StackSlider: Too many input arguments');                 %Check for wrong number of inputs
    return
end
switch nargin
    case 0                                         
        [FileName, FilePath]=uigetfile('*.lsm',...                          %No inputs, lets user pick a file
            'Choose lsm images to import',pwd,...                           %"pwd" returns the folder listed as "Current Folder" in the main window
            'MultiSelect','off');                                           %Allow only one lsm file to be chosen
        if FilePath(1)==0                                                   %If no files are chosen, break execution
            disp('Error in StackSlider: No files chosen');
            return
        end
        S.I=makestack(strcat(FilePath,FileName),'uint8');                   %Make the stack and force the class to be uint8, store in struct S
    case 2                                                                  
        S.I=makestack(varargin{1},'uint8'); 
        S.I2=makestack(varargin{2},'uint8');
        %One input, pass it along to makestack and force the class to be uint8, store in struct S
%     case 2                                                                  
%         S.I=makestack(varargin{1},varargin{2});                             %Two inputs, pass both along to makestack, store in struct S
    case 3 
        S.I=makestack(varargin{1},'uint8'); 
        S.I2=makestack(varargin{2},'uint8');
        screenToUse = varargin{3};
end
%S.I2_temp = S.I2; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Build the figure for the GUI.                                          
% All handles and the image stack are stored in the struct SS             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
SCRSZ = screensize(screenToUse);   %Get user's screen size
figheight=SCRSZ(4)*0.9;                                                     %A reasonable height for the GUI
figwidth=SCRSZ(3)*0.9;                                                      %A reasonable width for the GUI (the height of the screen*1.1)
pad=10;                                                                     %Inside padding in the GUI
smallstep=1/(size(S.I,3)-1);                                                %Step the slider will take when moved using the arrow buttons: 1 frame
largestep=smallstep*10;                                                     %Step the slider will take when moved by clicking in the slider: 10 frames
%%%%%%Create the figure itself. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S.fh = figure('units','pixels',...                                          
    'position',[figwidth/4 50 figwidth figheight],...
    'menubar','figure',...
    'name','StackSlider',...
    'numbertitle','off',...
    'resize','off');
%%%%%%Create the axes for image display. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if SCRSZ(4) > SCRSZ(3)
    widthVal = 20;
    heightVal = 15;
    widthDiv = 1;
    heightDiv = 2;
else
    widthVal = 20;
    heightVal = 8;
    widthDiv = 2;
    heightDiv = 1;
end
S.ax = axes('units','pixels',...                                            
    'position',[4*pad 10*pad figwidth/widthDiv-widthVal*pad figheight/heightDiv-heightVal*pad],...
    'fontsize',10,...
    'nextplot','replacechildren');
S.ax2 = axes('units','pixels',...                                            
    'position',[4*pad figheight/heightDiv-(heightVal-25)*pad figwidth/widthDiv-widthVal*pad figheight/heightDiv-heightVal*pad],...
    'fontsize',10,...
    'nextplot','replacechildren');
%%%%%%Create a slider and an editbox for picking frames. %%%%%%%%%%%%%%%%%%
S.sl = uicontrol('style','slide',...                                        
    'unit','pix',...                           
    'position',[2*pad 5*pad figwidth-16*pad 2*pad],...
    'min',1,'max',size(S.I,3),'val',1,...
    'SliderStep', [smallstep largestep]);
%[2*pad figheight/heightDiv-(heightVal-20)*pad figwidth-16*pad figheight/heightDiv-(heightVal-20)*pad+10]
S.sl2 = uicontrol('style','slide',...                                        
    'unit','pix',...                           
    'position',[2*pad figheight/heightDiv-(heightVal-20)*pad figwidth-16*pad 2*pad],...
    'min',1,'max',size(S.I2,3),'val',1,...
    'SliderStep', [smallstep largestep]);

S.ed = uicontrol('style','edit',...                                         
    'unit','pix',...
    'position',[figwidth-10*pad 5*pad 4*pad 2*pad],...
    'fontsize',12,...
    'string','1');
S.ed2 = uicontrol('style','edit',...                                         
    'unit','pix',...
    'position',[figwidth-10*pad figheight/heightDiv-(heightVal-20)*pad 4*pad 2*pad],...
    'fontsize',12,...
    'string','1');

S.cmtext=uicontrol('style','text',...                                       %Textbox describing the editbox
    'unit','pix',...
    'position',[figwidth-13.5*pad 7*pad 10*pad 2*pad],...
    'fontsize',10,...
    'string','Current frame:');
S.cmtext2=uicontrol('style','text',...                                       %Textbox describing the editbox
    'unit','pix',...
    'position',[figwidth-13.5*pad figheight/heightDiv-(heightVal-23)*pad 10*pad 2*pad],...
    'fontsize',10,...
    'string','Current frame:');
%%%%%%Create a popupmenu for picking colormap. %%%%%%%%%%%%%%%%%%%%%%%%%%%%
S.cmstr={'Gray','Hot','Copper','Jet'};                                      %Strings with the allowed colormaps

S.cmtext=uicontrol('style','text',...                                       %Textbox describing the popupmenu
    'unit','pix',...
    'position',[figwidth-11*pad 11*pad 8*pad 3*pad],...
    'fontsize',10,...
    'string','Colormap:');
S.cmpopup = uicontrol('style','popupmenu',...                               %Popup menu for picking                        
    'unit','pix',...
    'position',[figwidth-11*pad 10*pad 8*pad 2*pad],...
    'String', S.cmstr);

S.cmpopup2 = uicontrol('style','popupmenu',...                               %Popup menu for picking                        
    'unit','pix',...
    'position',[figwidth-11*pad figheight/heightDiv-(heightVal-27)*pad  8*pad 2*pad],...
    'String', S.cmstr);
S.cmtext2=uicontrol('style','text',...                                       %Textbox describing the popupmenu
    'unit','pix',...
    'position',[figwidth-11*pad figheight/heightDiv-(heightVal-29)*pad 8*pad 3*pad],...
    'fontsize',10,...
    'string','Colormap:');

%%%%%%Create a button group for smoothing. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

S.smtext = uicontrol('style','text',...                                       %Ttextbox describing the button group
    'unit','pix',...
    'position',[figwidth-14.5*pad 69*pad 12*pad 3*pad],...
    'fontsize',10,...
    'string','Smoothing opts: ');
S.smbutgrp = uibuttongroup('unit','pix',...                                 %The button group itself
     'position',[figwidth-14.5*pad 50*pad 13*pad 20*pad]);


S.smtext2 = uicontrol('style','text',...                                       %Ttextbox describing the button group
    'unit','pix',...
    'position',[figwidth-14.5*pad figheight/heightDiv-(heightVal-84)*pad 12*pad 3*pad],...
    'fontsize',10,...
    'string','Smoothing opts: ');
S.smbutgrp2 = uibuttongroup('unit','pix',...                                 %The button group itself
     'position',[figwidth-14.5*pad figheight/heightDiv-(heightVal-65)*pad 13*pad 20*pad]);

S.bttext = uicontrol('style','text',...                                       %Ttextbox describing the button group
    'unit','pix',...
    'position',[figwidth-14.5*pad 46*pad 14*pad 3*pad],...
    'fontsize',10,...
    'string','Contrast/Brightness: ');
S.btbutgrp = uibuttongroup('unit','pix',...                                 %The button group itself
     'position',[figwidth-14.5*pad 27*pad 13*pad 20*pad]);

S.smnone=uicontrol('style','radio',...                                      %Radio button for no smoothing
    'parent',S.smbutgrp,...
    'position',[0.5*pad 17*pad 13*pad 2*pad],...
    'fontsize',8,...    
    'string','No smoothing');
S.smgauss=uicontrol('style','radio',...                                     %Radio button for gaussian smoothing
    'parent',S.smbutgrp,...
    'position',[0.5*pad 13*pad 13*pad 2*pad],...
    'fontsize',10,...    
    'string','Gaussian');
S.smgausssizetext=uicontrol('style','text',...                              %Textbox "size" to set filter size. 
    'unit','pix',...        
    'parent',S.smbutgrp,...
    'position',[0.5*pad 11*pad 4*pad 2*pad],...
    'fontsize',8,...
    'string','Size');
S.smgausssize = uicontrol('style','edit',...                                %Editbox for size of gaussian kernel. Note that this number will be used
    'unit','pix',...                                                        %as the radius of the filter, NOT the default "matrix size". This is to
    'parent',S.smbutgrp,...                                                 %make the "size" argument behave the same as for the disk filter.
    'position',[0.5*pad 9*pad 4*pad 2*pad],...                              %(see the callback function "smoothing")
    'fontsize',10,...
    'string','3');
S.smgausssigmatext=uicontrol('style','text',...                             %Textbox for standard deviation
    'unit','pix',...
    'parent',S.smbutgrp,...
    'position',[5*pad 11*pad 4*pad 2*pad],...
    'fontsize',8,...
    'string','Stdev');
S.smgausssigma = uicontrol('style','edit',...                               %Editbox for standard deviation of gaussian kernel
    'unit','pix',...
    'parent',S.smbutgrp,...
    'position',[5*pad 9*pad 4*pad 2*pad],...
    'fontsize',10,...
    'string','1');
S.smdisk=uicontrol('style','radio',...                                      %Radio button for averaging disk smoothing
    'parent',S.smbutgrp,...
    'position',[0.5*pad 5*pad 9*pad 2*pad],...
    'fontsize',10,...    
    'string','Averaging');
S.smdisktext=uicontrol('style','text',...                                   %Textbox "size"
    'parent',S.smbutgrp,...    
    'unit','pix',...
    'position',[0.5*pad 3*pad 4*pad 2*pad],...
    'fontsize',8,...
    'string','Size');
S.smdisksize = uicontrol('style','edit',...                                 %Editbox for size of averaging kernel
    'parent',S.smbutgrp,...    
    'unit','pix',...
    'position',[0.5*pad pad 4*pad 2*pad],...
    'fontsize',10,...
    'string','3');
set(S.smbutgrp,'SelectedObject',S.smnone);                                  %Set the default button checked in the group

S.btnone=uicontrol('style','Pushbutton',...                                      %Radio button for no smoothing
    'parent',S.btbutgrp,...
    'position',[0.5*pad 17*pad 11*pad 2*pad],...
    'fontsize',8,...    
    'string','No adjusting');
S.btbright=uicontrol('style','text',...                                     %Radio button for gaussian smoothing
    'parent',S.btbutgrp,...
    'position',[0.5*pad 13*pad 9*pad 2*pad],...
    'fontsize',10,...    
    'string','Brightness');
S.btIncbutton = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'parent',S.btbutgrp,...
    'position',[0.5*pad 11*pad 6*pad 2*pad],...
    'fontsize',8,...
    'string','Increase b');
S.btDecbutton = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'parent',S.btbutgrp,...
    'position',[6.5*pad 11*pad 6*pad 2*pad],...
    'fontsize',8,...
    'string','Decrease b');
S.btText=uicontrol('style','edit',...                                   %Textbox "size"
    'parent',S.btbutgrp,...    
    'unit','pix',...
    'position',[3.5*pad 9*pad 6*pad 2*pad],...
    'fontsize',8,...
    'string','0');


S.btcontrast=uicontrol('style','text',...                                      %Radio button for averaging disk smoothing
    'parent',S.btbutgrp,...
    'position',[0.5*pad 5*pad 7*pad 2*pad],...
    'fontsize',10,...    
    'string','Contrast');
S.btIncCbutton = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'parent',S.btbutgrp,...
    'position',[0.5*pad 3*pad 6*pad 2*pad],...
    'fontsize',8,...
    'string','Increase c');
S.btDecCbutton = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'parent',S.btbutgrp,...
    'position',[6.5*pad 3*pad 6*pad 2*pad],...
    'fontsize',8,...
    'string','Decrease c');
S.btCText=uicontrol('style','edit',...                                   %Textbox "size"
    'parent',S.btbutgrp,...    
    'unit','pix',...
    'position',[3.5*pad 0.5*pad 6*pad 2*pad],...
    'fontsize',8,...
    'string','0');

S.start1 = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'position',[figwidth-14.5*pad 22*pad 13*pad 4*pad],...
    'fontsize',12,...
    'string','Start data');
S.stop1 = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'position',[figwidth-14.5*pad 17*pad 13*pad 4*pad],...
    'fontsize',12,...
    'string','Stop data');

S.start2 = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'position',[figwidth-14.5*pad figheight/heightDiv-(heightVal-55)*pad 13*pad 4*pad],...
    'fontsize',12,...
    'string','Start temp');
S.stop2 = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'position',[figwidth-14.5*pad figheight/heightDiv-(heightVal-50)*pad 13*pad 4*pad],...
    'fontsize',12,...
    'string','Stop temp');

S.smnone2=uicontrol('style','radio',...                                      %Radio button for no smoothing
    'parent',S.smbutgrp2,...
    'position',[0.5*pad 17*pad 13*pad 2*pad],...
    'fontsize',8,...    
    'string','No smoothing');
S.smgauss2=uicontrol('style','radio',...                                     %Radio button for gaussian smoothing
    'parent',S.smbutgrp2,...
    'position',[0.5*pad 13*pad 13*pad 2*pad],...
    'fontsize',10,...    
    'string','Gaussian');
S.smgausssizetext2=uicontrol('style','text',...                              %Textbox "size" to set filter size. 
    'unit','pix',...        
    'parent',S.smbutgrp2,...
    'position',[0.5*pad 11*pad 4*pad 2*pad],...
    'fontsize',8,...
    'string','Size');
S.smgausssize2 = uicontrol('style','edit',...                                %Editbox for size of gaussian kernel. Note that this number will be used
    'unit','pix',...                                                        %as the radius of the filter, NOT the default "matrix size". This is to
    'parent',S.smbutgrp2,...                                                 %make the "size" argument behave the same as for the disk filter.
    'position',[0.5*pad 9*pad 4*pad 2*pad],...                              %(see the callback function "smoothing")
    'fontsize',10,...
    'string','3');
S.smgausssigmatext2=uicontrol('style','text',...                             %Textbox for standard deviation
    'unit','pix',...
    'parent',S.smbutgrp2,...
    'position',[5*pad 11*pad 4*pad 2*pad],...
    'fontsize',8,...
    'string','Stdev');
S.smgausssigma2 = uicontrol('style','edit',...                               %Editbox for standard deviation of gaussian kernel
    'unit','pix',...
    'parent',S.smbutgrp2,...
    'position',[5*pad 9*pad 4*pad 2*pad],...
    'fontsize',10,...
    'string','1');
S.smdisk2=uicontrol('style','radio',...                                      %Radio button for averaging disk smoothing
    'parent',S.smbutgrp2,...
    'position',[0.5*pad 5*pad 9*pad 2*pad],...
    'fontsize',10,...    
    'string','Averaging');
S.smdisktext2=uicontrol('style','text',...                                   %Textbox "size"
    'parent',S.smbutgrp2,...    
    'unit','pix',...
    'position',[0.5*pad 3*pad 4*pad 2*pad],...
    'fontsize',8,...
    'string','Size');
S.smdisksize2 = uicontrol('style','edit',...                                 %Editbox for size of averaging kernel
    'parent',S.smbutgrp2,...    
    'unit','pix',...
    'position',[0.5*pad pad 4*pad 2*pad],...
    'fontsize',10,...
    'string','3');
set(S.smbutgrp2,'SelectedObject',S.smnone2);                                  %Set the default button checked in the group

%%%%%%Create a "reset" button to reset everything to defaults%%%%%%%%%%%%%%
S.resetbutton = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'unit','pix',...
    'position',[figwidth-13.5*pad figheight-100*pad 10*pad 4*pad],...
    'fontsize',12,...
    'string','Reset all');

S.resetbutton2 = uicontrol('style','pushbutton',...                          %Pushbutton to reset everything to defaults
    'unit','pix',...
    'position',[figwidth-13.5*pad figheight-15*pad 10*pad 4*pad],...
    'fontsize',12,...
    'string','Reset all');
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Draw the first frame of the stack and set callback functions           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%Draw the first frame of the stack%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S.Clims2=[0 prctile(S.I2(:),99)];  %Color limits for the plotting and colorbar. Needs to be done before callbacks are assigned
%median(median(squeeze(max(max(S.I),3))))
imagesc(S.ax2,flipud(squeeze(S.I2(:,:,1))),S.Clims2);  
%caxis([min(squeeze(S.I(:,:,1))), max(squeeze(S.I(:,:,1)))])
%Display the first frame
axis equal tight                                                            %Make sure it's to scale
setcm(S.cmpopup,[],S,S.Clims2)                                                            %Set colormap
colorbar                                                                    %Display a colorbar
%%%%%%Set callback functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


S.Clims=[0 prctile(S.I(:),99)];  %Color limits for the plotting and colorbar. Needs to be done before callbacks are assigned
S.val = 0; 
%median(median(squeeze(max(max(S.I),3))))
imagesc(S.ax, flipud(squeeze(S.I(:,:,end))),S.Clims);  
%caxis([min(squeeze(S.I(:,:,1))), max(squeeze(S.I(:,:,1)))])
%Display the first frame
axis equal tight                                                            %Make sure it's to scale
setcm(S.cmpopup,[],S,S.Clims)                                                            %Set colormap
colorbar                                                                    %Display a colorbar
%%%%%%Set callback functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set([S.ed,S.sl],'call',{@switchframe,S});                                   %Shared callback function for fram selection slider and editbar
set(S.cmpopup,'Callback',{@setcm,S,S.Clims});                                       %Callback function for changing colormap
set(S.smbutgrp,'SelectionChangeFcn',{@smoothing,S});                        %Callback function for smoothing radio buttons
set([S.smgausssize,S.smgausssigma,S.smdisksize],'call',{@smoothsize,S});    %Callback function for the smoothing edit boxes
set(S.resetbutton,'Callback', {@resetfunction,S});                          %Callback function for the reset button
set(S.btnone,'Callback',{@btAdjust,S});                        %Callback function for smoothing radio buttons
set(S.btIncbutton,'Callback',{@btAdjust,S});
set(S.btDecbutton,'Callback',{@btAdjust,S});
set(S.btIncCbutton,'Callback',{@btAdjust,S});
set(S.btDecCbutton,'Callback',{@btAdjust,S});
set([S.btCText,S.btText],'call',{@btAdjust,S});    %Callback function for the smoothing edit boxes

set([S.ed2,S.sl2],'call',{@switchframe2,S});                                   %Shared callback function for fram selection slider and editbar
set(S.cmpopup2,'Callback',{@setcm,S,S.Clims2});                                       %Callback function for changing colormap
set(S.smbutgrp2,'SelectionChangeFcn',{@smoothing,S});                        %Callback function for smoothing radio buttons
set([S.smgausssize2,S.smgausssigma2,S.smdisksize2],'call',{@smoothsize,S});    %Callback function for the smoothing edit boxes
set(S.resetbutton2,'Callback', {@resetfunction,S});                          %Callback function for the reset button
set(S.start1,'Callback', {@startStopExport,S});                          %Callback function for the reset button
set(S.start2,'Callback', {@startStopExport,S});                          %Callback function for the reset button
set(S.stop1,'Callback', {@startStopExport,S});                          %Callback function for the reset button
set(S.stop2,'Callback', {@startStopExport,S});                          %Callback function for the reset button

%set(S.exportbutton,'Callback',{@exportfunction,S});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Change colormap callback function                                      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=setcm(varargin)                                                 %varargin is {calling handle, eventdata, struct SS}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};    
clims =  varargin{4};   %Extract handle of calling object
eval(['cmap=colormap(', lower(S.cmstr{get(h,'value')}),...                 %Create a colormap cmap with 256 colors and the chosen colormap
    '(', num2str(clims(2)), '));']);
if get(h,'value')==1                                                        %If "jet" is chosen, set 0 to black and 255 to white
    %cmap(1,:)=[0 0 0];
    %cmap(end,:)=[1 1 1];
elseif get(h,'value')==2                                                    %If "gray" is chosen, set 0 to blue and 255 to red (like the range indicator on a Zeiss mic)
    cmap(1,:)=[0 0 1];
    cmap(end,:)=[1 0 0];
end
    
colormap(S.ax,cmap);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = startStopExport(varargin)
[h,S] = varargin{[1,3]};  
if contains(h.String, 'Start t')
    assignin('base','StartT',S.ed2.String)
elseif contains(h.String, 'Stop t')
    assignin('base','StopT',S.ed2.String)
elseif contains(h.String, 'Stop d')
    assignin('base','StopD',S.ed.String)
elseif contains(h.String, 'Start d')
    assignin('base','StartD',S.ed.String)
end
end
%% Move slider or write in frame editbox callback function                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = switchframe(varargin)                                         %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S
switch h                                                                    %Who called?
    case S.ed                                                               %The editbox called...
        sliderstate =  get(S.sl,{'min','max','value'});                     % Get the slider's info
        enteredvalue = str2double(get(h,'string'));                         % The new frame number
        
        if enteredvalue >= sliderstate{1} && enteredvalue <= sliderstate{2} %Check if the new frame number actually exists
            slidervalue=round(enteredvalue);
            set(S.sl,'value',slidervalue)                                   %If it does, move the slider there
        else
            set(h,'string',sliderstate{3})                                  %User tried to set slider out of range, keep value
            return
        end
    case S.sl                                                               %The slider called...
        slidervalue=round(get(h,'value'));                                  % Get the new slider value
        set(S.ed,'string',slidervalue) 
   
    
end
if get(S.smbutgrp,'SelectedObject')==S.smnone                              %Check if the smoothing is set to 'none'
    imagesc(S.ax,flipud(squeeze(S.I(:,:,size(S.I,3)-slidervalue))),S.Clims)                         % If it is, plot the new selected frame from the original stack
    setcm(S.cmpopup,[],S, S.Clims)
else
    smoothing(get(S.smbutgrp,'SelectedObject'),[],S)                       % If it isn't, plot the new selected frame from the smoothed stack
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = switchframe2(varargin)                                         %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S
switch h                                                                    %Who called?
    case S.ed2                                                               %The editbox called...
        sliderstate =  get(S.sl2,{'min','max','value'});                     % Get the slider's info
        enteredvalue = str2double(get(h,'string'));                         % The new frame number
        
        if enteredvalue >= sliderstate{1} && enteredvalue <= sliderstate{2} %Check if the new frame number actually exists
            slidervalue=round(enteredvalue);
            set(S.sl2,'value',slidervalue)                                   %If it does, move the slider there
        else
            set(h2,'string',sliderstate{3})                                  %User tried to set slider out of range, keep value
            return
        end
    case S.sl2                                                               %The slider called...
        slidervalue=round(get(h,'value'));                                  % Get the new slider value
        set(S.ed2,'string',slidervalue) 
                                                                %The slider called...
    
end
if get(S.smbutgrp,'SelectedObject')==S.smnone  
    Clims2=[S.Clims2(1)+str2num(S.btText.String)  S.Clims2(2)+str2num(S.btText.String)];  
   %Check if the smoothing is set to 'none'
    imagesc(S.ax2,flipud(squeeze(S.I2(:,:,slidervalue))),Clims2)                         % If it is, plot the new selected frame from the original stack
    setcm(S.cmpopup,[],S, S.Clims2)
else
    smoothing(get(S.smbutgrp,'SelectedObject'),[],S)                       % If it isn't, plot the new selected frame from the smoothed stack
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Smoothing opts editboxes callback function                             
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=smoothsize(varargin)                                            %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S
currbut=get(S.smbutgrp,'SelectedObject');                                   %Get handle to selected radio button (this function was called by an editbox)
if (h==S.smgausssize || h==S.smdisksize) && (str2double(get(h,'string'))<1) %Check if the filter size is set to less than one
    set(h,'string','1');                                                    % If it is, set it to one and return without action
    return
end
switch currbut                                                              %Get the current radio button
    case S.smnone                                                           % If it's 'none', return without action
        return
    case S.smgauss                                                          % If it's "gaussian", check if the edit was made in the "disk" editbox
        if h==S.smdisksize                                                  %  If it was, then return without action
            return
        end
    case S.smdisk                                                           % If it's "disk", check if the edit was made in one of the "gaussian" editboxes
        if h==S.smgausssize || h==S.smgausssigma                            %  If it was, then return without action
            return
        end
end
smoothing(currbut,[],S);                                                    %If you haven't "returned without action" yet, it's time to call the smoothing function with 
                                                                            %input that looks like the user just switched to that radio button. This needs to stay on the 
end                                                                         %last line of this function or below lines will be called after "smoothing" is done
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Change smoothing method or parameters for current smoothing callback   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=smoothing(varargin)                                             %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S
if h==S.smbutgrp                                                            %If called by a radio button, the calling handle will be the button group.
    h=varargin{2}.NewValue;                                                 %Set h to the handle of the selected radio button
end
currentframe=round(get(S.sl,'value'));                                      %Get current frame number
switch h                                                                    %Get handle of calling radio button
    case S.smnone                                                           % If caller is 'none', draw the current frame from the original stack 
        imagesc(flipud(squeeze(S.I(:,:,currentframe))),S.Clims)                     %  (this 'un-smoothes' if the current frame is smoothed)
        setcm(S.cmpopup,[],S)
        return                                                              %  Return to caller function so no filtering is done
    case S.smgauss                                                          % If caller is 'gaussian', create a gaussian filter
        filtsize=2*str2double(get(S.smgausssize,'string'))+1;               %  Filter size (recalc'd so that both filters uses the number as the radius)
        filtsigma=str2double(get(S.smgausssigma,'string'));                 %  Standard deviation for gaussian filter
        smfilt=fspecial('gaussian',filtsize,filtsigma);                     %  Make the filter
        
    case S.smdisk                                                           % If caller is 'disk', create an averaging disk filter
        filtsize=str2double(get(S.smdisksize,'string'));                    %  Filter size
        smfilt=fspecial('disk',filtsize);                                   %  Make the filter
end
S.Is=imfilter(S.I(:,:,currentframe),smfilt,'replicate');                    %Do the filtering, replicate border values outside frame
imagesc(flipud(S.Is),S.Clims)                                                       %Draw the filtered frame    
setcm(S.cmpopup,[],S)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Smoothing opts editboxes callback function                             
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=btAdjust(varargin)                                            %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S
                                          %If you haven't "returned without action" yet, it's time to call the smoothing function with 
                                                                            %input that looks like the user just switched to that radio button. This needs to stay on the 
if contains(h.String, 'No adjusting')
    set(S.btText,'String',0)
    Clims=[S.Clims(1)+str2num(S.btText.String)  S.Clims(2)+str2num(S.btText.String)];  
    set(S.ax, 'CLim', Clims);  
elseif contains(h.String, 'Increase b')
    set(S.btText,'String',num2str(str2num(S.btText.String) + 5))
    Clims=[S.Clims(1)+str2num(S.btText.String)  S.Clims(2)+str2num(S.btText.String)];  
    set(S.ax, 'CLim', Clims);  
elseif contains(h.String, 'Decrease b')
    set(S.btText,'String',num2str(str2num(S.btText.String) - 5))
    Clims=[S.Clims2(1)+str2num(S.btText.String)  S.Clims2(2)+str2num(S.btText.String)];  
    set(S.ax, 'CLim', Clims);     
elseif contains(h.String, 'Increase c')
elseif contains(h.String, 'Decrease c')
end     
end%last line of this function or below lines will be called after "smoothing" is done
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Change brightness/contrast method or parameters for current smoothing callback   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=brightCon(varargin)                                             %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S
if h==S.smbutgrp                                                            %If called by a radio button, the calling handle will be the button group.
    h=varargin{2}.NewValue;                                                 %Set h to the handle of the selected radio button
end
currentframe=round(get(S.sl,'value'));                                      %Get current frame number
switch h                                                                    %Get handle of calling radio button
    case S.smnone                                                           % If caller is 'none', draw the current frame from the original stack 
        imagesc(flipud(squeeze(S.I(:,:,currentframe))),S.Clims)                     %  (this 'un-smoothes' if the current frame is smoothed)
        setcm(S.cmpopup,[],S)
        return                                                              %  Return to caller function so no filtering is done
    case S.smgauss                                                          % If caller is 'gaussian', create a gaussian filter
        filtsize=2*str2double(get(S.smgausssize,'string'))+1;               %  Filter size (recalc'd so that both filters uses the number as the radius)
        filtsigma=str2double(get(S.smgausssigma,'string'));                 %  Standard deviation for gaussian filter
        smfilt=fspecial('gaussian',filtsize,filtsigma);                     %  Make the filter
        
    case S.smdisk                                                           % If caller is 'disk', create an averaging disk filter
        filtsize=str2double(get(S.smdisksize,'string'));                    %  Filter size
        smfilt=fspecial('disk',filtsize);                                   %  Make the filter
end
S.Is=imfilter(S.I(:,:,currentframe),smfilt,'replicate');                    %Do the filtering, replicate border values outside frame
imagesc(flipud(S.Is),S.Clims)                                                       %Draw the filtered frame    
setcm(S.cmpopup,[],S)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reset GUI to its starting state button callback function              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=resetfunction(varargin)                                         %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
S = varargin{3};                                                         
set(S.smgausssize,'string','3');                        
set(S.smgausssigma,'string','1');
set(S.smdisksize,'string','3');
set(S.smbutgrp,'SelectedObject',S.smnone);
set(S.sl,'value',1);
set(S.ed,'string',1);
set(S.cmpopup,'value',1)
colormap(S.ax,'Gray')
imagesc(flipud(squeeze(S.I(:,:,1))),S.Clims);
setcm(S.cmpopup,[],S)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Export current view button callback                                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function []=exportfunction(varargin)                                        %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
S=varargin{3};                                                              %Extract the struct S
switch get(S.smbutgrp,'SelectedObject')                                     %Check which smoothing was used, if any
    case S.smnone
        usedsmooth='None';                                                  %No smoothing
    case S.smdisk
        usedsmooth=['Disk averaging, radius '...                            %Disk smoothing, get radius
                    get(S.smdisksize,'string') ' pixels'];
    case S.smgauss
        usedsmooth=['Gaussian, radius ' get(S.smgausssize,'string')...      %Gaussian smoothing, get radius and stddev
                    ' pixels, stddev=' get(S.smgausssigma,'string')];
end
figure('Name',['Frame ' get(S.ed,'string') '. Smoothing: '...               %New figure with nice name
                usedsmooth],'NumberTitle','off')
copyobj(allchild(S.ax),axes);                                               %Copy all children of the GUI axes to axes in new fig
axis equal tight
setcm(S.cmpopup,[],S)
colorbar
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function that creates the 3D-array used
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [outstack]=makestack(arrayorfile,dataclass)                        %First input is either a filename or a 3D array, second is the class
if ischar(arrayorfile)                                                      %If it's a filename, read the file using tiffread
    lsm= tiffread(arrayorfile);
    
    if length(lsm(1,1).data)>1                                              %If there are several channels, pick which one to display
        chstrgs = inputdlg({'Pick channel to display:'},...
            'Enter channel',1,{'1'});
        ch=str2double(chstrgs{1});
    end
    outstack=zeros(size(lsm(1).data{1},1), size(lsm(1).data{1},2),...       %Preallocate memory for the image stack
        length(lsm));
    for k=1:length(lsm)
        outstack(:,:,k)=lsm(k).data{ch};                                    %Build the stack. There should be a better way to do this...
    end
else
    outstack=arrayorfile;                                                   %If the input was an array, that array is our image stack
    clear arrayorfile
end
maxval=max(outstack(:));                                                    %The maximum value of the stack for colormap scaling
currentclass=class(outstack);                                               %The data class of the data
switch dataclass                                                            %Switch on the desired data class 
    case 'uint8'                                                            %User wants uint8 (quickest and least memory needed)
        if ~strcmp(currentclass,'uint8')                                    %If it's already uint8, do nothing
            outstack=uint8(255*double(outstack)/double(maxval));            %Normalize and cast to uint8
        end
        
    case 'uint16'                                                           %User wants uint16
        if strcmp(currentclass,'uint8')                                     %If the class is uint8, this is stupid.
            disp('Displaying an 8-bit image as a 16-bit image is stupid. uint8 used.')
        elseif ~strcmp(currentclass,'uint16')                               %If it's already uint16, do nothing
            outstack=uint16(65535*double(outstack)/double(maxval));         %Normalize and cast to uint16
        end
end
end
