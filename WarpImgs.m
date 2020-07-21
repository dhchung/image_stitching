function WarpImgs(n,Img,ImgIndices,BaseImg,H_in)
%Warping img 1 to img 2 with homography H
%Following Matlab Example of Image Stitching
%https://kr.mathworks.com/help/vision/examples/feature-based-panoramic-image-stitching.html

TargetImg = find(BaseImg~=ImgIndices);

x1 = [1 1 1]';
x2 = [size(Img{1},2),size(Img{1},1) 1]';
x3 = [1 size(Img{1},1) 1]';
x4 = [size(Img{1},2) 1 1]';

X = zeros(3, 4*size(ImgIndices,1));
X(:,1:4) = [x1 x2 x3 x4];

for i=1:size(TargetImg,1)
    Hx = [H_in(:,:,i)*x1, H_in(:,:,i)*x2, H_in(:,:,i)*x3, H_in(:,:,i)*x4];
    Hx = Hx./Hx(3,:);
    X(:,4*i+1:4*(i+1)) = Hx;
end


MinX = round(min(X,[],2));
MaxX = round(max(X,[],2));
height = MaxX(2)-MinX(2);
width = MaxX(1)-MinX(1);
xLimits =[MinX(1) MaxX(1)];
yLimits =[MinX(2) MaxX(2)];
panoramaView = imref2d([height width], xLimits, yLimits);
panorama = uint8(zeros([height width 3]));

blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');
t = projective2d(eye(3));
warpedImage = imwarp(Img{BaseImg}, t, 'OutputView', panoramaView);
mask = imwarp(true(size(Img{BaseImg},1),...
    size(Img{BaseImg},2)),t, 'OutputView', panoramaView);
panorama = step(blender, panorama, warpedImage, mask);

for i=1:size(TargetImg,1)
    fprintf("Warping img#%d to img#%d...\n", TargetImg(i), BaseImg);
    A = H_in(:,:,i)';
    A = double(A);
    t = projective2d(A);
    warpedImage = imwarp(Img{TargetImg(i)}, t, 'OutputView', panoramaView);
    mask = imwarp(true(size(Img{TargetImg(i)},1),...
        size(Img{TargetImg(i)},2)), t, 'OutputView', panoramaView);
    panorama = step(blender, panorama, warpedImage, mask);
end
figure(n);
imshow(panorama)
end
