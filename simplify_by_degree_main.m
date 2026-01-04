function expr_simplified = simplify_by_degree_main(expr, mode, k, varargin)
% Simplify expression by retaining terms with lowest/highest degree in small/large variables
% Input:
%   expr: symbolic expression (polynomial or polynomial fraction)
%   mode: 'small' or 'large'
%       'small': use small variable degree, keep k lowest degree terms
%       'large': use large variable degree, keep k highest degree terms
%   k: number of degree levels to keep
%   varargin: variable set based on mode
%       for mode='small': small_vars
%       for mode='large': large_vars
% Output:
%   expr_simplified: simplified expression

    % Validate mode parameter
    if ~ismember(mode, {'small', 'large'})
        error('Mode parameter must be ''small'' or ''large''');
    end
    
    % Process variable sets based on mode
    if strcmp(mode, 'small')
        if nargin < 4
            error('In small mode, small_vars parameter is required');
        end
        small_vars = varargin{1};
        large_vars = [];  % Empty large variable set
    else
        if nargin < 4
            error('In large mode, large_vars parameter is required');
        end
        large_vars = varargin{1};
        small_vars = [];  % Empty small variable set
    end
    
    % Get numerator and denominator
    [num, den] = numden(expr);
    
    if isequal(den, 1)
        % Polynomial case
        expr_simplified = simplify_by_degree(num, small_vars, large_vars, mode, k);
    else
        % Fraction case: simplify numerator and denominator separately
        num_simplified = simplify_by_degree(num, small_vars, large_vars, mode, k);
        den_simplified = simplify_by_degree(den, small_vars, large_vars, mode, k);
        
        % Combine and simplify
        expr_simplified = simplify(num_simplified / den_simplified);
    end
end

function S_simplified = simplify_by_degree(S, small_vars, large_vars, mode, k)
% Simplify polynomial by retaining terms with specified degree levels
% Input:
%   S: symbolic polynomial
%   small_vars: vector of small variables (can be empty)
%   large_vars: vector of large variables (can be empty)
%   mode: 'small' or 'large'
%   k: number of degree levels to keep
% Output:
%   S_simplified: simplified polynomial

    % Expand polynomial
    S_expanded = expand(S);
    
    % Get all variables
    all_vars = symvar(S_expanded);
    
    % If no variables, it's a constant, return directly
    if isempty(all_vars)
        S_simplified = S_expanded;
        return;
    end
    
    % Get monomials and coefficients using coeffs
    [coeffs_vec, monomials] = coeffs(S_expanded, all_vars);
    
    % Calculate degree for each monomial
    degrees = zeros(1, length(monomials));
    for i = 1:length(monomials)
        mon = monomials(i);
        deg_sum = 0;
        
        if strcmp(mode, 'small')
            % Calculate small variable degree
            for j = 1:length(small_vars)
                deg = polynomialDegree(mon, small_vars(j));
                deg_sum = deg_sum + deg;
            end
        else
            % Calculate large variable degree
            for j = 1:length(large_vars)
                deg = polynomialDegree(mon, large_vars(j));
                deg_sum = deg_sum + deg;
            end
        end
        degrees(i) = deg_sum;
    end
    
    % Find all unique degrees and sort them
    unique_degrees = unique(degrees);
    
    if strcmp(mode, 'small')
        % Small mode: ascending order, keep lowest k degrees
        sorted_degrees = sort(unique_degrees);
        if k <= length(sorted_degrees)
            retained_degrees = sorted_degrees(1:min(k, length(sorted_degrees)));
        else
            retained_degrees = sorted_degrees;  % If k exceeds total degree levels, keep all
        end
    else
        % Large mode: descending order, keep highest k degrees
        sorted_degrees = sort(unique_degrees, 'descend');
        if k <= length(sorted_degrees)
            retained_degrees = sorted_degrees(1:min(k, length(sorted_degrees)));
        else
            retained_degrees = sorted_degrees;  % If k exceeds total degree levels, keep all
        end
    end
    
    % Construct simplified polynomial: keep only terms with specified degrees
    S_simplified = sym(0);
    for i = 1:length(monomials)
        if ismember(degrees(i), retained_degrees)
            S_simplified = S_simplified + coeffs_vec(i) * monomials(i);
        end
    end
    
    % Final simplification
    S_simplified = simplify(S_simplified);
end