function [Final]=edge_detection();
I = imread('.\testset\104.jpg');
figure,imshow(I);
Ibin = im2bw(I); 
 
% The direction filters 
 
kernel0 = [-1 -1 -1;2 2 2 ;-1 -1 -1]; %0 degree 
 
kernel45 = [-1 -1 2; -1 2 -1 ;2 -1 -1]; %45 degree 
 
kernel90 = [-1 2 -1; -1 2 -1; -1 2 -1]; %90 degree 
 
kernel135 = [2 -1 -1; -1 2 -1 ;-1 -1 2]; %135 degree 
 
Kernels{1} = kernel0; 
Kernels{2} = kernel45; 
Kernels{3} = kernel90; 
Kernels{4} = kernel135; 
 
% Creating Gaussian Pyramid 
 
h = fspecial('gaussian'); %Gaussian kernel default hsize 3x3 
 
im = I; 
Pyramid{1} = im; 
for i = 2:4 
 im = imfilter(im,h,'conv'); %convolve with gaussian filter 
 im = imresize(im,0.5); %down-sample by 1/2 
 Pyramid{i} = im;  
 %figure,imshow(Pyramid{i}); 
end 
 
% Convolving images at each level in the Pyramid with each 
% direction filter 
 
for m = 1:4 
 for n = 1:4 
 Conv{m,n} = imfilter(Pyramid{m},Kernels{n},'conv'); 
 end 
end 
 
% Resize images to original image size 
 
for m = 1:4 
 for n = 1:4 
 Conv2{m,n} = imresize(Conv{m,n},[size(I,1) size(I,2)]); 
 end 
end 
 
% Total of all directional filter responses 
 
for m = 1:4 
 
 total{m} = im2bw(Conv2{1,m}+Conv2{2,m}+Conv2{3,m}+Conv2{4,m}); 
end 
 
Total = imadd((total{1,1}+total{1,3}),(total{1,2}+total{1,4})); 
%figure,imshow(Total),title('Total of directions'); 
 
% Otsu threshold 
level = graythresh(double(total{1,3})); 
EdgeStrong = im2bw(total{1,3},level); 
%figure,imshow(EdgeStrong),title('Strong'); 
 
%dilation with SE 1x3 
SE = strel('line',3,0); 
IDilated = imdilate(EdgeStrong,SE); 
%figure,imshow(IDilated),title('Dilated'); 
 
%Closing with vetical SE 
m = round(size(EdgeStrong,1)/25); 
SE2 = strel('line',m,90); 
IClosed = imclose(IDilated,SE2); 
%figure,imshow(IClosed),title('Closed'); 
% Weak edges  53
EdgeWeak = IClosed-IDilated; 
%figure,imshow(EdgeWeak),title('Weak'); 
 
%Combining strong and weak edges 
Edge90 = EdgeStrong + EdgeWeak; 
%figure,imshow(Edge90),title('Edge90'); 
 
%Thinning operation 
Thinned = bwmorph(Edge90,'thin',Inf); 
%figure,imshow(Thinned),title('Thinned'); 
 
% Eliminate long edges 
[L,N] = bwlabel(Thinned,4); 
St = regionprops(L,'all'); 
Short90 = double(Thinned); 
 
for i=1:length(St) 
 if St(i).MajorAxisLength > (size(I,1)/5) 
 
 c = St(i).PixelList(:,1); 
 r = St(i).PixelList(:,2); 
 Short90(r,c)=0; 
 end 
end
%figure,imshow(Short90),title('Short edges');
 
SED = strel('line',5,90); 
candidate = imdilate(Short90,SED); 
%figure,imshow(candidate),title('Candidate'); 
 
Refined = immultiply(candidate,Total); 
%figure,imshow(Refined),title('refined'); 
ref = imdilate(Refined,strel('square',4)); 
 
%Feature Map 
bic0 = im2bw(total{1,1}); 
bic90 = im2bw(total{1,3}); 
bic45 = im2bw(total{1,2}); 
bic135 = im2bw(total{1,4}); 
 
T1 = (bic0 & bic90); 
T2 = (bic45 & bic135); 
 
T = T1 + T2; 
%figure,imshow(T),title('AND result'); 
FeatureMap = (ref&T);  
 
 
BigSE2 = strel('disk',6); 
FMDilated = imdilate(FeatureMap,BigSE2); 
%figure,imshow(FMDilated),title('Dilated Feature Map'); 
 
% Heuristic Filtering 
% Remove those regions which have Area < MaxArea/20 
% Remove those regions which have Width/Height < 0.1 
 
[Lab,Num] = bwlabel(FMDilated,4); 
Regions = regionprops(Lab,'all'); 
MaxArea = 0; 
 
for r=1:length(Regions) 
 
 Area = Regions(r).Area; 
 if(MaxArea < Area) 
 MaxArea = Area; 
 end 
end 
i=1; 
for r=1:length(Regions) 
 
 A = Regions(r).Area; 
 if(A < MaxArea/20) 
 
 FMDilated = bwareaopen(FMDilated,A); 
 end 
 
end 
 
NewImage = double(FMDilated); 
 
for i=1:length(Regions) 
 if (Regions(i).MajorAxisLength / Regions(i).MinorAxisLength)>6 
 
 c = Regions(i).PixelList(:,1); 
 r = Regions(i).PixelList(:,2); 
 NewImage(r,c)=0; 
 end 
end 
%figure,imshow(NewImage); 
 
 
% Final result  
 
Final = immultiply(~(Ibin),im2bw(NewImage)); 
figure,imshow(Final),title('Result');
