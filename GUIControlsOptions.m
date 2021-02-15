classdef GUIControlsOptions
    
    methods(Static)
        
        function out = GetSetUIControls(handles)
            persistent UIControls;

            if nargin == 1
                UIControls = handles;
            end

            out = UIControls;
        end
        
        function SetIteratedPointVisualMenu()
            
            handles = GUIControlsOptions.GetSetUIControls;
            handles.VisualIteratedObjectMenu.Visible='on';
            handles.VisualIteratedObjectMenu.String=[{'Re -> Im'},{'|z| -> phi(z)'},{'lg|z+1| -> phi(z)'},{'lg |Re+1| -> lg|Im+1|'}];
            
        end
        
        
    end
    
end