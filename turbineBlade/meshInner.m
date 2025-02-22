function [elements,boundaries] = meshInner(pp, arc_length, arc_length_at_max_y, flipped)
    config

    % if omesh
    s_fine = [linspace(0, arc_length_at_max_y, n_top + 2*k_inner +1)(1:end-1), ...
          linspace(arc_length_at_max_y, arc_length, n_bottom + 2*k_inner + 1)(1:end-1)];

    % if xmesh
    %     s_fine = [linspace(0, arc_length_at_max_y, n_top+1)(1:end-1), ...
    %     linspace(arc_length_at_max_y, arc_length, n_bottom+1)(1:end-1)];
    %     points_top = ppval(pp, s_fine(1:n_top+1))';
    %     points_bottom = [ppval(pp, s_fine(n_top + 1:end))'; points_top(1,:)];
    %     n = n_top;

    if flipped == true 
        s_fine(s_fine >= arc_length_at_max_y) = s_fine(s_fine >= arc_length_at_max_y) - arc_length;
    end
    points_top = ppval(pp, s_fine(1:n_top + 2*k_inner+1))';
    points_bottom = [ppval(pp, s_fine(n_top + 2*k_inner + 1:end))'; points_top(1,:)];
    n = n_top + 2*k_inner;


    point_at_min = ppval(pp, 0);
    point_at_max = ppval(pp, arc_length_at_max_y);
    x = point_at_min(1);

    elements = [];
    boundaries = [];

    p14 = findBisectNode(point_at_min', points_top(2, :), points_bottom(end-1, :));
    element = [];
    element(1,:) = point_at_min';
    element(2,:) = points_bottom(end-1, :);
    element(3,:) = p14;
    element(4,:) = points_top(2, :);
    elements(end+1, :, :) = element;
    boundaries(end+1, :) = [size(elements, 1); 10;];
    p24 = findBisectNode(point_at_max', points_top(end-1, :), points_bottom(2, :));
    element = [];
    element(1,:) = point_at_max';
    element(2,:) = points_top(end-1, :);
    element(3,:) = p24;
    element(4,:) = points_bottom(2, :);
    elements(end+1, :, :) = element;
    boundaries(end+1, :) = [size(elements, 1); 10;];

    for i = 2:n-1
        element = [];
        element(1,:) = points_top(i+1, :);
        element(2,:) = points_top(i,:);
        element(3,:) = (i-2)/(n-2)*p24 + (n-i)/(n-2)*p14;
        element(4,:) = (i-1)/(n-2)*p24 + (n-i-1)/(n-2)*p14;
        elements(end+1, :, :) = element;
        boundaries(end+1, :) = [size(elements, 1); 10;];
        element = [];
        element(1,:) = points_bottom(i+1, :);
        element(2,:) = points_bottom(i,:);
        element(3,:) = (i-2)/(n-2)*p14 + (n-i)/(n-2)*p24;
        element(4,:) = (i-1)/(n-2)*p14 + (n-i-1)/(n-2)*p24;
        elements(end+1, :, :) = element;
        boundaries(end+1, :) = [size(elements, 1); 10;];
    end
    checkCounterClockwise(elements)
end

function p4 = findBisectNode(p1, p2, p3)
    % Vectors defining the plane
    p4 = p1 + 3/4*(p2 - 2*p1 + p3);
end
% function p4 = findBisectNode(p1, p2, p3)
%     % Vectors defining the plane
%     P1 = p1(2:3);
%     P2 = p2(2:3);
%     P3 = p3(2:3);
%     v12 = P2 - P1; % Vector from P1 to P2
%     v13 = P3 - P1; % Vector from P1 to P3
%
%     A = [v12(1), v12(2);
%          v13(1), v13(2)];
%     b = [dot(v12, P2);
%          dot(v13, P3)];
%     P4 = (A \ b)';
%     p4= [];
%     p4(1) = p1(1);
%     p4(2:3) = P4;
% end

function U=bilinearInterp(corners, s, t, sp, tp)
    P0_t = (1-t) * corners(1, :) + t * corners(2, :);
    P1_t = (1-tp) * corners(4, :) + tp * corners(3, :);
    P2_s = (1-s) * corners(1, :) + s * corners(4, :);
    P3_s = (1-sp) * corners(2, :) + sp * corners(3, :);
    P00 = corners(1, :);
    P10 = corners(4, :);
    P01 = corners(2, :);
    P11 = corners(3, :);
    
    U = (1-s) * P0_t + s * P1_t + (1-t) * P2_s + t * P3_s ...
        - (1-s)*(1-t)*P00 - s*(1-t)*P10 - (1-s)*t*P01 - s*t*P11;

end


function checkCounterClockwise(elements)
    for k = 1:size(elements, 1)
        element = squeeze(elements(k, :, :));
        for i = 1:4
            v1 = element(i, :);
            v2 = element(mod(i, 4) + 1, :);
            v3 = element(mod(i + 1, 4) + 1, :);
            edge1 = v2 - v1;
            edge2 = v3 - v2;
            
            cross_prod = cross(edge1, edge2);
            
            if cross_prod(1) <= 0
                fprintf('Inner Element %d is not counterclockwise at corner %d.\n', k, i);
            end
        end
    end
end


