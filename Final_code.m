clc;clear; close all

%Clear all variables and windows and read in the image
img = imread('132.jpg');

%Create a red channel image and greayscaled image
img_red = img(:,:,1);
img_g = rgb2gray(img);

%Create a mask of the image to identify the microscope region
mask = im2bw(img_g, 50/255);
[r,c,channel] = size(mask);

%Find bounding box for circle
blank = zeros(size(mask));
row_start = 0;
row_end = 0;
col_start = 0;
col_end = 0;
for i = 1:r
    for j = 1:c
        if mask(i,j) == 1
            row_start = i;
            break
        end
    end
    if row_start ~= 0
        break
    end
end
for i = r:-1:1
    for j = 1:c
        if mask(i,j) == 1
            row_end = i;
            break
        end
    end
    if row_end ~= 0
        break
    end
end
for i = 1:c
    for j = 1:r
        if mask(j,i) == 1
            col_start = i;
            break
        end
    end
    if col_start ~= 0
        break
    end
end
for i = c:-1:1
    for j = 1:r
        if mask(j,i) == 1
            col_end = i;
            break
        end
    end
    if col_end ~= 0
        break
    end
end

%make a mask and apply it to the image
vec = mask(floor((row_end-row_start)/2), :, :);
d = length(find(vec == 1));
for i = 1:r
    for j = 1:c
        dist = sqrt((i-((row_end-row_start)/2 + row_start))^2 + (j - ((col_end-col_start)/2 + col_start))^2);
        if dist <= d/2-20
            blank(i,j) = 1;
        else
            blank(i,j) = 0;
        end
    end
end

%Find an edge detection method to use
figure,
subplot(2,2,1)
imshow(img_red)
title('original')
subplot(2,2,2)
imshow(edge(img_red, 'sobel'))
title('Sobel')
subplot(2,2,3)
imshow(edge(img_red, 'canny'))
title('Canny')
subplot(2,2,4)
imshow(edge(img_red, 'prewitt'))
title('Prewitt')

%Apply mask to image and dilate the edges
mask = imbinarize(blank);
edge_detected = edge(img_red, 'canny');
dilate = imdilate(imdilate(edge_detected, strel('line', 3,0)), strel('line', 3, 90));
dilate(mask(:,:) == 0) = 0;

%Remove the boundary circle created from the edge detection
for i = 1:r
    for j = 1:c
        dist = sqrt((i-((row_end-row_start)/2 + row_start))^2 + (j - ((col_end-col_start)/2 + col_start))^2);
        if dist == d/2-20
            dilate(i,j) = 0;
        end
    end
end

%Fill in the holes of the image
filled = imfill(imclearborder(dilate), 'holes');

%Display the dilated and filled images
figure,
subplot(1,2,1)
imshow(dilate)
subplot(1,2,2)
imshow(filled)

%Find and displaythe circular cells
figure,
[center, radii] = imfindcircles(dilate, [40 100], ObjectPolarity="dark", Sensitivity= .95, method= "PhaseCode");
imshow(img)
h = viscircles(center, radii);

%Create a mask using the coordinates and radii from the find circle command
blank = zeros(size(blank));
for i = 1:length(radii)
    for j = 1:r
        for k = 1:c
            dist = sqrt((j-center(i,2))^2 + (k - center(i,1))^2);
            if dist <= radii(i) 
                blank(j,k) = 1;
            end
        end
    end
end

%Create an inverted mask and apply it to dilated image to remove the cells
%that are normal
inv_mask2 = zeros(size(blank));
inv_mask2(blank(:,:) == 0) = 1;
imshow(inv_mask2)
inv_mask2 = inv_mask2 .* dilate;
inv_mask2 = imfill(imclearborder(inv_mask2), 'holes');

%Apply the final mask over the image and burn the mask onto the original
%image and display it
figure, 
final_img = bsxfun(@times, img, cast(inv_mask2, 'like', img));
imshow(imoverlay(img,inv_mask2))
