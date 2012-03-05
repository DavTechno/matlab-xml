function varargout = xmlwrite(a, xmlfile)
%XMLWRITE write a MATLAB struct as well-formatted xml.
%  XMLWRITE creates an xml file from a MATLAB struct, paying no attention to
%  order or other nice things like that.
%
%  XMLWRITE(STRUCT, XMLFILE) where STRUCT is a MATLAB struct and XMLFILE is a
%  file handle, writes STRUCT to xml.
%
%  XML = XMLWRITE(STRUCT, XMLFILENAME) where XMLFILENAME is the name of a 
%  file to open, opens a file with that name and writes to it. The xml string is
%  only returned if requested.
%
%  Example:
%  >> a.note = struct('to','Bob','from','Sally','heading','Hey there', ...
%                  'body', 'Yo, yo! What''s up?');
%  >> xmlwrite(a, 'example.xml')
%  >> cat example.xml
%  <note>
%    <to>Bob</to>
%    <from>Sally</from>
%    <heading>Hey there</heading>
%    <body>Yo, yo! What's up?</body>
%  </note>
%
%See also: xmlwrite

if ischar(xmlfile)
    % XMLFILENAME
    xmlfile = fopen(xmlfile,'w');
end

b = length(dbstack);
xml = '<?xml version="1.0"?>';
xml = [xml printnode(a,b)];

try
    fprintf(xmlfile, xml);
catch ex
    switch ex.identifier
        case 'MATLAB:badfid_mx'
            error('Bad file identifier passed to XMLREAD as XMLFILE.');
        otherwise
            throw(ex);
    end
end

if nargout == 1
    varargout{1} = xml;
end

end

function xml = printnode(a,b)
%PRINTNODE return the name of the current node as a string.

c = length(dbstack);    % The stack depth of this call.
d = c-b-1;              % The relative stack depth for indentation.

switch class(a)
    case 'struct'
        % If the node has subnodes, get them recursively.
        flds = fieldnames(a);
        xml = char(10);
        for i = 1:length(flds)
            % Also check for arrays of structs.
            tag1 = ['<' flds{i} '>'];
            tag2 = ['</' flds{i} '>'];
            
            if isstruct(a.(flds{i})) && length(a.(flds{i})) > 1
                for j = 1:length(a.(flds{i}))
                    xml = [xml repmat('    ',1,d) tag1 ...
                        printnode(a.(flds{i})(j),b) tag2 char(10)];
                end
            else
                xml = [xml repmat('    ',1,d) tag1 ...
                    printnode(a.(flds{i}),b) tag2 char(10)];
            end
        end

    case 'double'
        % If the node contains numeric data, print them as numbers or matrices.
        switch sum(size(a) == [1 1])
            case 2
                xml = a;
            case 1
                xml = ['[' num2str(a) ']'];
            case 0
                xml = '[';
                for i = 1:size(a,1)
                    xml = [xml '[' a(i,:) '];'];
                end
                xml = [xml ']'];
            otherwise
                msg = 'Too many dimensions in numerice data.';
                error('XMLPARSE:tooManyDiensions', msg);
        end
        
    case 'char'
        % Strings are easy: just print them out.
        xml = a;

    otherwise
        % Someone trying to throw me off! I'll throw it right back at 'em!
        msg = 'Your struct contains an invalid data type.';
        ex = MException('XMLPARSE:invalidData', msg);
        throw(ex);
end

end