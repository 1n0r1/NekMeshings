

% Mesh slices
config
xs = [];
sliceElements = [];
sliceBoundaries = [];
sliceSplines = {};
for i = 0:slice_spacing:208
    filename = sprintf('slices/slice%04d.txt', i);
    slice = readSliceFile(filename);
    x = slice(1,1);
    flipped = false;
    if x > 0
        flipped = true;
    end
    [pp, arc_length, arc_length_at_max_y] = fitSpline(slice, flipped);
    [elements, boundaries, pp_coarse] = meshOuterOMesh(pp, arc_length, arc_length_at_max_y, flipped);
    sliceElements(end+1, :, :, :) = elements;
    sliceBoundaries = boundaries;
    xs(end+1) = x;
    sliceSplines{size(sliceElements,1)} = pp_coarse;
end
if ~ismember(0, xs) || norm(xs + flip(xs)) > 1e-6
    disp('Error: slices do not contain x=0 or not symmetric around x=0')
end

% Add connecting splines
connectingSplines = {};
for i = 1:size(sliceSplines{1}.breaks, 2)
    splinePoints = [];
    x = [];
    for j=1:length(sliceSplines)
        if (xs(j) <= 0)
            splinePoints(end+1, :) = ppval(sliceSplines{j}, sliceSplines{j}.breaks(i));
        else 
            k = mod(i + n_top + 2*k_inner - 1, 2*n_top + 4*k_inner) + 1;
            splinePoints(end+1, :) = ppval(sliceSplines{j}, sliceSplines{j}.breaks(k));
        end
        x(end+1) = splinePoints(end, 1);
    end
    pp_coarse = spline(x, splinePoints');
    connectingSplines{i} = pp_coarse;
end
% plotSplines

% Connect slices
elements = [];
boundaries = [];
[numSlices, numElements, numVertices, dim] = size(sliceElements);
for k = 1:(numSlices - 1)
    count_wall = 0;
    spline1 = sliceSplines{k};
    spline3 = sliceSplines{k+1};
    for elem = 1:numElements
        vertices_layer_k = squeeze(sliceElements(k, elem, :, :)); % 4 x 3
        vertices_layer_k1 = squeeze(sliceElements(k+1, elem, :, :)); % 4 x 3
        element = [vertices_layer_k; vertices_layer_k1]; % 8 x 3
        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        [isBoundary, idx] = ismember(elem, sliceBoundaries(:, 1));
        if isBoundary
            tag = sliceBoundaries(idx, 2);
            if tag == 1
                boundaries(end+1, :) = [size(elements,1); 3; 1];
                count_wall = count_wall + 1;
                spline2 = connectingSplines{count_wall+1};
                spline4 = connectingSplines{count_wall};

                j = count_wall;
                if xs(k) > 0
                    j = mod(count_wall + n_top + 2*k_inner - 1, 2*n_top + 4*k_inner) + 1;
                end
                spline1piece = spline1.coefs((j-1)*3 + 1: (j-1)*3 + 3,:);
                spline1start = spline1.breaks(j);
                spline1end = spline1.breaks(j + 1);

                j = count_wall;
                if xs(k+1) > 0
                    j = mod(count_wall + n_top + 2*k_inner - 1, 2*n_top + 4*k_inner) + 1;
                end
                spline3piece = spline3.coefs((j-1)*3 + 1: (j-1)*3 + 3,:);
                spline3start = spline3.breaks(j);
                spline3end = spline3.breaks(j + 1);

                spline2piece = spline2.coefs((k-1)*3 + 1: (k-1)*3 + 3,:);
                spline2start = spline2.breaks(k);
                spline2end = spline2.breaks(k+1);

                spline4piece = spline4.coefs((k-1)*3 + 1: (k-1)*3 + 3,:);
                spline4start = spline4.breaks(k);
                spline4end = spline4.breaks(k+1);

                filename = sprintf('surfaces/surface%08d.txt', size(elements,1));
                fid = fopen(filename, "w");
                fprintf(fid, '%15.7g %15.7g %15.7g %15.7g\n', spline1piece.');
                fprintf(fid, '%15.7g %15.7g\n', spline1start, spline1end);
                fprintf(fid, '%15.7g %15.7g %15.7g %15.7g\n', spline2piece.');
                fprintf(fid, '%15.7g %15.7g\n', spline2start, spline2end);
                fprintf(fid, '%15.7g %15.7g %15.7g %15.7g\n', spline3piece.');
                fprintf(fid, '%15.7g %15.7g\n', spline3start, spline3end);
                fprintf(fid, '%15.7g %15.7g %15.7g %15.7g\n', spline4piece.');
                fprintf(fid, '%15.7g %15.7g\n', spline4start, spline4end);

                % Close the file
                fclose(fid);

                % nPoints = 100;
                %
                % figure; hold on; grid on;
                % xlabel('X'); ylabel('Y'); zlabel('Z');
                % title('3D Spline Segments');
                % view(3);
                %
                % t1 = linspace(spline1start, spline1end, nPoints);
                % x1 = polyval(spline1piece(1, :), t1 - spline1start);
                % y1 = polyval(spline1piece(2, :), t1 - spline1start);
                % z1 = polyval(spline1piece(3, :), t1 - spline1start);
                % plot3(x1, y1, z1, 'r', 'LineWidth', 2);
                % t3 = linspace(spline3start, spline3end, nPoints);
                % x3 = polyval(spline3piece(1, :), t3 - spline3start);
                % y3 = polyval(spline3piece(2, :), t3 - spline3start);
                % z3 = polyval(spline3piece(3, :), t3 - spline3start);
                % plot3(x3, y3, z3, 'b', 'LineWidth', 2);
                % t2 = linspace(spline2start, spline2end, nPoints);
                % x2 = polyval(spline2piece(1, :), t2 - spline2start);
                % y2 = polyval(spline2piece(2, :), t2 - spline2start);
                % z2 = polyval(spline2piece(3, :), t2 - spline2start);
                % plot3(x2, y2, z2, 'g', 'LineWidth', 2);
                % t4 = linspace(spline4start, spline4end, nPoints);
                % x4 = polyval(spline4piece(1, :), t4 - spline4start);
                % y4 = polyval(spline4piece(2, :), t4 - spline4start);
                % z4 = polyval(spline4piece(3, :), t4 - spline4start);
                % plot3(x4, y4, z4, 'k', 'LineWidth', 2);
                %
                % legend('Spline 1', 'Spline 3', 'Spline 2', 'Spline 4');
                % xlabel('Parameter t');
                % ylabel('Value');
                % title('Plot of 4 Spline Segments');
                % grid on;
                % hold off;
                % axis equal;
                % pause;
            end
            if tag == 2 
                boundaries(end+1, :) = [size(elements,1); 1; 2];
            end
            if tag == 3
                boundaries(end+1, :) = [size(elements,1); 1; 2];
            end
        end


    end
end



% Add end caps
config
for i = 0:0
    filename = sprintf('slices/slice%04d.txt', i);
    slice = readSliceFile(filename);
    [pp, arc_length, arc_length_at_max_y] = fitSpline(slice, false);
    [elementsOuter, boundariesOuter] = meshOuterOMesh(pp, arc_length, arc_length_at_max_y, false);
    [elementsInner, boundariesInner] = meshInner(pp, arc_length, arc_length_at_max_y, false);
    for elem = 1:size(elementsInner, 1)
        layer_k = squeeze(elementsInner(elem,:, :)); 
        layer_k1 = squeeze(elementsInner(elem,:, :)); 
        layer_k1(:,1) = -R_x;
        element = [layer_k1; layer_k]; % 8 x 3
        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        boundaries(end+1, :) = [size(elements,1); 6; 1];
        boundaries(end+1, :) = [size(elements,1); 5; 3];
    end
    for elem = 1:size(elementsOuter, 1)
        layer_k = squeeze(elementsOuter(elem,:, :)); 
        layer_k1 = squeeze(elementsOuter(elem,:, :)); 
        layer_k1(:,1) = -R_x;
        element = [layer_k1; layer_k]; % 8 x 3
        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        boundaries(end+1, :) = [size(elements,1); 5; 3];

        [isBoundary, idx] = ismember(elem, sliceBoundaries(:, 1));
        if isBoundary
            tag = sliceBoundaries(idx, 2);
            if tag == 2 
                boundaries(end+1, :) = [size(elements,1); 1; 2];
            end
            if tag == 3
                boundaries(end+1, :) = [size(elements,1); 1; 2];
            end
        end
    end
end

for i = 208:208
    filename = sprintf('slices/slice%04d.txt', i);
    slice = readSliceFile(filename);
    [pp, arc_length, arc_length_at_max_y] = fitSpline(slice, true);
    [elementsOuter, boundariesOuter] = meshOuterOMesh(pp, arc_length, arc_length_at_max_y, true);
    [elementsInner, boundariesInner] = meshInner(pp, arc_length, arc_length_at_max_y, true);
    for elem = 1:size(elementsInner, 1)
        layer_k = squeeze(elementsInner(elem,:, :)); 
        layer_k1 = squeeze(elementsInner(elem,:, :)); 
        layer_k1(:,1) = R_x;
        element = [layer_k; layer_k1]; % 8 x 3
        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        boundaries(end+1, :) = [size(elements,1); 5; 1];
        boundaries(end+1, :) = [size(elements,1); 6; 3];
    end
    for elem = 1:size(elementsOuter, 1)
        layer_k = squeeze(elementsOuter(elem,:, :)); 
        layer_k1 = squeeze(elementsOuter(elem,:, :)); 
        layer_k1(:,1) = R_x;
        element = [layer_k; layer_k1]; % 8 x 3
        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        boundaries(end+1, :) = [size(elements,1); 6; 3];

        [isBoundary, idx] = ismember(elem, sliceBoundaries(:, 1));
        if isBoundary
            tag = sliceBoundaries(idx, 2);
            if tag == 2 
                boundaries(end+1, :) = [size(elements,1); 1; 2];
            end
            if tag == 3
                boundaries(end+1, :) = [size(elements,1); 1; 2];
            end
        end
    end
end

% Wrap cylinder
xs = squeeze(xs);
xs = xs(:);
half_pos = floor(size(xs,1)/2)+1;
xs = xs(half_pos:end);
xs(end+1) = R_x;
[cylElements, cylBoundaries] = wrapCylinder(xs);
config
zs = linspace(R_b, R_t, k_inner*2 + 1)(:);
for k = 2:size(zs,1)
    z_prev = zs(k-1);
    z = zs(k);
    for elem = 1:size(cylElements,1)
        cylElemk = squeeze(cylElements(elem, :, :));
        cylElemk(:, 3) = z_prev;
        cylElemk1 = squeeze(cylElements(elem, :, :));
        cylElemk1(:, 3) = z;
        element = [cylElemk; cylElemk1];

        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        [isBoundary, idx] = ismember(elem, cylBoundaries(:, 1));
        if isBoundary
            boundaries(end+1, :) = [size(elements,1); 3; 3];
        end
        if k == 2
            boundaries(end+1, :) = [size(elements,1); 5; 2];
        end
        if k == size(zs,1)
            boundaries(end+1, :) = [size(elements,1); 6; 2];
        end
    end
end

[cylElements, cylBoundaries] = wrapCylinder(xs);
cylElements(:, :, 2) = -cylElements(:, :, 2);
zs = linspace(R_b, R_t, k_inner*2 + 1)(:);
for k = 2:size(zs,1)
    z_prev = zs(k-1);
    z = zs(k);
    for elem = 1:size(cylElements,1)
        cylElemk = squeeze(cylElements(elem, :, :));
        cylElemk(:, 3) = z_prev;
        cylElemk1 = squeeze(cylElements(elem, :, :));
        cylElemk1(:, 3) = z;
        element = [cylElemk1; cylElemk];

        checkLeftHanded(element);

        elements(end+1, :, :) = element;
        [isBoundary, idx] = ismember(elem, cylBoundaries(:, 1));
        if isBoundary
            boundaries(end+1, :) = [size(elements,1); 3; 3];
        end
        if k == 2
            boundaries(end+1, :) = [size(elements,1); 6; 2];
        end
        if k == size(zs,1)
            boundaries(end+1, :) = [size(elements,1); 5; 2];
        end
    end
end

size(elements)
size(boundaries)
% plotElements3D(elements)

exportREA("output.rea", elements, boundaries)
% plotBC(elements, boundaries)
