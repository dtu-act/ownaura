% writelog
%
% Backspace character \berase only last line in the listbox handles.
% Newline characters \n should only be present at the last part of the
% string
function writelog(dest,varargin)

if ~iscell(dest)
    dest={dest};
end

for n = 1:length(dest)
    if ischar(dest{n})
        if isdir(fileparts(dest{n}))
            if isempty(strfind(varargin{1},'\b')) %don't write counters to text files
                fid = fopen(dest{n}, 'at');
                fprintf(fid,varargin{:});
            fclose(fid);
            end
        else
            warning('Invalid text file location for writing log. Use full path')
        end
    elseif ishandle(dest{n}) && dest{n}~=0
        A = cellstr(get(dest{n},'String'));
%         A = A{1:end-1};
        if nargin > 2
            A{end} = sprintf([A{end},varargin{1}],varargin{2:end});
        else
            A{end} =  sprintf([A{end},varargin{1}]);
        end
        while ~isempty(regexp(A{end},'\b','once'))
            A{end} = regexprep(A{end},'.\b|^\b','','once');
        end
        if regexp(varargin{1},'\\n$','once')
            A{end+1}='';
        end
        set(dest{n},'value',length(A))
        set(dest{n},'String',A)
        drawnow
    elseif ~dest{n}
        fprintf(varargin{:});
    else
        warning('Invalid handles for writing log')
    end
end