function [h,Im,x,y,attrib] = plot_basemap(authority,code,basemap)
% plot_basemap downloads and plots a basemap image in the current
% map projection. 
% 
%% Syntax
% 
%  plot_basemap(authority,code)
%  plot_basemap(authority,code,'basemap',basemap) 
%  [h,Im,x,y,attrib] = plot_basemap(...) 
% 
%% Description 
% 
%  plot_basemap(authority,code) fills the current extents of a map with a
%  satellite image basemap. The current map must already be open and
%  in the projection defined by authority,code. The authority can be 'EPSG'
%  or 'ESRI' and the code is numeric. 
%
%  plot_basemap(authority,code,basemap) specifies the type of
%  basemap called by readBasemapImage. Default is "satellite", and can be
%  changed to "streets", "streets-light", or "streets-dark".
% 
%  [h,Im,x,y,attrib] = plot_basemap(...) returns the handle h of the plotted
%  image, and image data Im, its coordinates, and attrib given by readBasemapImage. 
% 
%% Example: Jakobshavn Glacier 
% Initialize a map of Jakobshavn Glacier in North Polar Stereographic
% projection and plot a basemap. 
% 
%  figure
%  axis([-196980    -171290   -2285131   -2256724])
%  plot_basemap('EPSG',3413)
% 
%% Author Info
% Written by Chad Greene, NASA Jet Propulsion Laboratory, July 2024. 
% 
% See also readBasemapImage

%% Error checks

narginchk(2,3) 
assert(~isequal(axis,[0 1 0 1]),'A map must be initiated before calling plot_basemap.')

if nargin==2
    basemap = 'satellite'; 
end

%% 

% Define the map projection: 
proj = projcrs(code,'authority',authority); 

% Get current map extents: 
xl = xlim; 
yl = ylim; 

% Define a buffer: 
buf = hypot(diff(xl),diff(yl))/100; % buffer is 1% of current diagonal limits  

% Get geo coordinates of buffered image coordinates: 
[lat,lon] = projinv(proj,[xl(1)-buf xl(2)+buf xl(2)+buf xl(1)-buf],...
    [yl(1)-buf yl(1)-buf yl(2)+buf yl(2)+buf]);

% Get the lat,lon limits of the buffered image: 
latlim = [min(lat) max(lat)]; 
lonlim = [min(lon) max(lon)];

% Read the basemap image from the web: 
[A,R,attrib] = readBasemapImage(basemap,latlim,lonlim); 

% Define a grid to fill the map (resolution basemap image resolution divided by 3 to meet Nyquist) 
x = xl(1):R.CellExtentInWorldX/3:xl(2); 
y = yl(2):-R.CellExtentInWorldY/3:yl(1); 
[X,Y] = meshgrid(x,y); 

% Convert map grid coordinates to geo: 
[Lat,Lon] = projinv(proj,X,Y); 

% Convert geo map grid coordinates to the projection of the downloaded basemap image:  
[Xb,Yb] = projfwd(R.ProjectedCRS,Lat,Lon); 

% Interpolate downloaded image to our new grid: 
Im = zeros(size(Lat,1),size(Lat,2),3,'uint8'); 
for k = 1:3
    Im(:,:,k) = mapinterp(A(:,:,k),R,Xb,Yb);
end

% Plot the image: 
hold on
h = image(x,y,Im); 
uistack(h,'bottom'); % sends it to the bottom of the graphical stack
daspect([1 1 1]) % equal limits 

if nargout==0
    clear h
end

end







