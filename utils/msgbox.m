function h = msgbox(varargin)
    % Suppress msgbox: do nothing or log if needed
    disp('[Suppressed msgbox]');
    if nargout > 0
        h = [];  % return empty if output is expected
    end
end