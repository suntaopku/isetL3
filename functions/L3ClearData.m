function L3small = L3ClearData(L3)


% L3small = L3ClearData(L3)
%
% Make a minimal version of the L3 structure by eliminating the training
% data.  This is primarily used to store the L3 structure in a camera.

L3small = L3Create;
L3small = L3Set(L3small,'name',L3Get(L3,'name'));
L3small = L3Set(L3small,'type',L3Get(L3,'type'));
L3small = L3Set(L3small,'design sensor',L3Get(L3,'design sensor'));
L3small = L3Set(L3small,'filters',L3Get(L3,'filters'));
L3small = L3Set(L3small,'training',L3Get(L3,'training'));
L3small = L3Set(L3small,'clusters',L3Get(L3,'clusters'));

% Following probably will break with new scenes because of the
% change in the illuminant structure.

trainingilluminant = sceneGet(L3Get(L3,'scene',1),'illuminant');
%This should be the illumianint in energy
% The updated line that should work with new scenes is below.            
%             trainingilluminant = sceneGet(L3Get(L3,'scene',1),'illuminant energy');
L3small = L3Set(L3small,'trainingilluminant',trainingilluminant);            


% Clear out the assignment of patchnum and clusters
for patchnum = 1: prod(size(L3small.clusters))
    if isfield(L3small.clusters{patchnum},'members')
        L3small.clusters{patchnum} = rmfield(L3small.clusters{patchnum},'members');
    end
end

% Clear flat and saturation indices from L3 structure
L3small = L3ClearIndicesData(L3small);