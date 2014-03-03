% CC.m 
% 
% Connected Component Based Text region extraction algorithm 
% 
% 
% 
function [FinalRes]=cc()
I = imread('text.png');
figure,imshow(I);

% Convert to YUV color space 
yuv = rgb2ycbcr(I); 
 
YChannel = yuv(:,:,1); % Y Channel 

 
% Generate Edge Image from Gray Image 
 
X=size(YChannel,1); 
Y=size(YChannel,2); 
x=0; 
y=0; 
left=0; 
upper=0; 
rightUpper=0; 
 
for x=2:X-1 
 for y=2:Y-1 
 left = abs(YChannel(x,y)-YChannel(x-1,y)); 
 upper = abs(YChannel(x,y)-YChannel(x,y-1)); 
 rightUpper = abs(YChannel(x,y)-YChannel(x+1,y-1)); 
 YEdge(x,y) = max(max(left,upper),rightUpper); 
 end 
end 
 
%figure,imshow(YEdge); 
 
% Increase contrast by sharpening 
H = fspecial('unsharp'); 
sharpEdge = imfilter(YEdge,H,'replicate'); 
%figure,imshow(sharpEdge),title('Sharpened Edge Image'); 
 
gt = graythresh(sharpEdge); 
b = im2bw(sharpEdge,gt); 
b = bwareaopen(b,4); 
b1 = imdilate(b,strel('rectangle',[2 5])); 
%figure,imshow(b1); 
 
% Calculate Horizontal and vertical projection profiles 
 
S1 = sum(b1,1); % vertical y 
S2 = sum(b1,2); % horizontal x 
 

 
 
Ty = mean(S1) + max(S1)/10; %Vertical threshold 
 
% Supress all pixels with value > Ty 
for i=1:length(S1) 
 if S1(i) > Ty 
 S1(i)=0; 
 end 
end 
 
 
VEdge = zeros(size(b1)); 
for y=1:size(VEdge,1)  
 for x=1:length(S1) 
 if( S1(x) == 0 ) 
 VEdge(y,x) = 0; 
 else 
 VEdge(y,x) = b1(y,x); 
 end 
 end 
end 
%figure,imshow(VEdge),title('Vertical Projection pixels'); 
 
Tx = mean(S2)/20; %horizontal thresh 
 
% Supress all pixels with value < Tx 
for j=1:length(S2) 
 if S2(j) < Tx 
 S2(j)=0; 
 end 
end 
 
 
HEdge = zeros(size(b1)); 
if (size(b1,1)<size(b1,2)) 
 for x=1:size(HEdge,1) 
 for y=1:length(S2) 
 if( S2(y) == 0 ) 
 HEdge(x,y) = 0; 
 else 
 HEdge(x,y) = b1(x,y); 
 end 
 end 
 end 
else 
 for y=1:length(S2) 
 for x=1:size(HEdge,2) 
 if( S2(y) == 0 ) 
 HEdge(y,x) = 0; 
 else 
 HEdge(y,x) = b1(y,x); 
 end 
 end 
 end 
end 
 
%figure,imshow(HEdge),title('Horizontal Projection pixels'); 
 
TotalEdge = imadd(HEdge,VEdge);  
 
%figure,imshow(TotalEdge); 
 
medFilt = medfilt2(TotalEdge,[4 4]); 
%figure,imshow(medFilt),title('Noise Removed'); 
 
 
Final = immultiply(b,medFilt); 
%figure,imshow(Final); 
 
HSE = strel('line',10,90); 
VSE = strel('line',10,0); 
Final1 = imopen(Final,HSE); 
Final2 = imopen(Final,VSE); 
newFinal = Final-(Final1+Final2); 
newFin = bwmorph(newFinal,'majority'); 
newFin = imdilate(newFin,strel('disk',6)); 
%figure,imshow(newFin); 
 
% Segment out non-text regions using major to minor axis ratio 
 
[Lab,N] = bwlabel(newFin,4); 
Regions = regionprops(Lab,'all'); 
MaxArea = 0; 
 
for r=1:length(Regions) 
 Area = Regions(r).Area; 
 if(MaxArea < Area) 
 MaxArea = Area; 
 end 
end 
 
for r=1:length(Regions) 
 A = Regions(r).Area; 
 if(A < MaxArea/20) 
 newFin = bwareaopen(newFin,A); 
 end 
end 
%figure,imshow(newFin); 
 
[newLab,newN] = bwlabel(newFin,4); 
newRegions = regionprops(newLab,'all'); 
J = double(newFin); 
for r=1:length(newRegions) 
 major = newRegions(r).MajorAxisLength; 
 minor = newRegions(r).MinorAxisLength;  
 R = major/minor; 
 if(R>10) 
 
 PListx = newRegions(r).PixelList(:,1); 
 PListy = newRegions(r).PixelList(:,2); 
 
 J(PListy,PListx)=0; 
 end 
end 

 
 
RR = imerode(J,strel('line',3,90)); 
RR = imdilate(RR,strel('disk',5)); 
 
FinalRes = immultiply(b,RR); 
figure,imshow(FinalRes),title('Result');
end
