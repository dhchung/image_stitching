function WarpImg(n,Img_1,Img_2,H)
%Warping img 1 to img 2 with homography H
%Following Matlab Example of Image Stitching
%https://kr.mathworks.com/help/vision/examples/feature-based-panoramic-image-stitching.html

%Make borders to get the results clearly
IM = 255*uint8(ones(size(Img_1,1),size(Img_1,2),1));

Img1 = uint8(zeros(size(Img_1,1),size(Img_1,2),3));
Img1(:,:,1)=IM;
Img1(10:end-9,10:end-9,:)=Img_1(10:end-9,10:end-9,:);

Img2 = uint8(zeros(size(Img_1,1),size(Img_1,2),3));
Img2(:,:,2)=IM;
Img2(10:end-9,10:end-9,:)=Img_2(10:end-9,10:end-9,:);

x1 = [1 1 1]';
x2 = [size(Img1,2),size(Img1,1) 1]';
x3 = [1 size(Img1,1) 1]';
x4 = [size(Img1,2) 1 1]';

x11 = H*x1;
x21 = H*x2;
x31 = H*x3;
x41 = H*x4;

x11 = x11/x11(3);
x21 = x21/x21(3);
x31 = x31/x31(3);
x41 = x41/x41(3);

X = [x1 x2 x3 x4 x11 x21 x31 x41];
MinX = round(min(X,[],2));
MaxX = round(max(X,[],2));
height = MaxX(2)-MinX(2);
width = MaxX(1)-MinX(1);
xLimits =[MinX(1) MaxX(1)];
yLimits =[MinX(2) MaxX(2)];
panoramaView = imref2d([height width], xLimits, yLimits);
panorama = uint8(zeros([height width 3]));


A = H';
A = double(A);

blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');

t = projective2d(A);
warpedImage = imwarp(Img1, t, 'OutputView', panoramaView);
mask = imwarp(true(size(Img1,1),size(Img1,2)), t, 'OutputView', panoramaView);
panorama = step(blender, panorama, warpedImage, mask);

t = projective2d(eye(3));
warpedImage = imwarp(Img2, t, 'OutputView', panoramaView);
mask = imwarp(true(size(Img2,1),size(Img2,2)), t, 'OutputView', panoramaView);
panorama = step(blender, panorama, warpedImage, mask);

figure(n);
imshow(panorama)

end
