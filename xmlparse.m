function a = xmlparse(xmlfile)
%XMLPARSE read an xml document and recreate the parse tree as a MATLAB struct.
%  XMLPARSE can actually only read a subset of xml documents into a MATLAB 
%  struct. Any xml document that contains only data the lowest level of the
%  parse tree, so that data and elements are not intermingled allows the
%  document to be read into a struct.
%
%  TREE = XMLPARSE(XMLFILE) where XMLFILE is a well-formed xml document, returns
%    a struct, TREE where each field corresponds to an element of the document,
%    and the value enclosed by that element to the content.
%
%  Example:
%  >> !echo 
%    "<?xml version="1.0"?>
%     <note>
%       <to>Bob</to>
%       <from>Sally</from>
%       <heading>Hey there</heading>
%       <body>Yo, yo! What's up?</body>
%     </note>" > example.xml
%  >> tree = xmlparse('example.xml')
%  tree =
%    note : [1x1 struct]
%  >> tree.note
%  ans =
%       to : 'Bob'
%     from : 'Sally'
%  subject : 'Hey there'
%     body : 'Yo, yo! What's up?'
%
%See also: xmlread

% Open and read the file into a MATLAB cell array.
fid = fopen(xmlfile,'r');
tline = fgetl(fid);
xmltext = fscanf(fid,'%c');
xmltext(xmltext==10)=[];
fclose(fid);
a = getnode(xmltext);

end

function a = getnode(xmltext)
%GETNODE fill in each node of the parse tree.
%  GETNODE either:
%    - reads in the content for the current node, or
%    - recursively calls itself for all the subnodes of the current node.
%
%  A = GETNODE(XMLTEXT) reads the string XMLTEXT
%
%See also: xmlparse

if ~isempty(strfind(xmltext,'<'))
    
    a = [];
    while ~isempty(strfind(xmltext,'<'))

        % NOTE: this will skip over any non-tag content.
        % Find the name of the tag to read.
        ind1 = strfind(xmltext,'<'); ind1 = ind1(1);
        ind2 = strfind(xmltext,'>'); ind2 = ind2(1);
        tagname = xmltext(ind1+1:ind2-1);
        if strfind(tagname,' ')
            % Dump the extra stuff.
            % TODO: should remember the extra stuff and do something with it?
            ind = strfind(tagname,' ');
            tagname = tagname(1:ind-1)
        end
        tlen = length(tagname);
        
        % Locate the beginning and end of the content in that tag.
        tagend = strfind(xmltext,['</' tagname '>']);
        tagend = tagend(1);
        
        % Recursively do the same for all tags one level below.
        if isfield(a,tagname)
            j = length(a.(tagname));
            a.(tagname)(j+1) = getnode(xmltext((ind2+1):(tagend-1)));
        else
            a.(tagname) = getnode(xmltext((ind2+1):(tagend-1)));
        end

        % Throw away fields that have been read.
        xmltext = xmltext((tagend+tlen+3):end);

    end

else
    if isanumber(xmltext)
        a = eval(['[' xmltext ']']);
    else
        a = xmltext;
    end
end

end

function tf = isanumber(text)
%ISANUMBER decides if the text is supposed to represent numeric data.
%
%  TF = ISANUMBER(TEXT) 

tf = isempty(setdiff(text,' .,e0123456789'));

end