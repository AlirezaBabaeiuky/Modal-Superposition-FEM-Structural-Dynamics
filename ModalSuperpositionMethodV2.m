% Modal superposition method for structural dynamics 
clc
clear all
close all

% Create a modal analysis model for a 3-D problem.
modelM = createpde( 'structural' , 'modal-solid' );

%Create the geometry and include it in the model. 
gm = multicuboid(0.05 , 0.003 , 0.003);
modelM.Geometry = gm;
figure(1)
pdegplot(modelM , 'EdgeLabels' , 'on' , 'VertexLabels' , 'on' );
% view([95 5])
view([95 10])

% Generate mesh
msh = generateMesh(modelM);

% Specify mechanical properties 
structuralProperties(modelM,'YoungsModulus',210E9, ...
                            'PoissonsRatio',0.3, ...
                            'MassDensity',7800);

% Specify minimal constraints on one end of the beam to prevent rigid body modes.
structuralBC(modelM , 'Edge' , 4 , 'Constraint' , 'fixed');
structuralBC(modelM , 'Vertex' , 7 , 'Constraint' , 'fixed');

% Solve in the range of 0 to 500000, get the 1st one slightly smaller than
% the fundamental frequency 
Rm = solve(modelM , 'FrequencyRange' , [-0.1 , 500000]);

%Transient Analysis
%Create a transient analysis model for a 3-D problem.
modelD = createpde( 'structural' , 'transient-solid' );

% Specify the geometry and mesh
modelD.Geometry = gm;
modelD.Mesh = msh;

% Mechanical properties 
structuralProperties( modelD , 'YoungsModulus' , 210E9 , ...
                            'PoissonsRatio' , 0.3 , ...
                            'MassDensity' , 7800 );

% Specify the same minimal constraints on one end of the beam to prevent
% rigid body modes.
structuralBC(modelD , 'Edge', 4 , 'Constraint' , 'fixed' );
structuralBC(modelD , 'Vertex' , 7 , 'Constraint' , 'fixed' );

% Apply a sinusoidal force on the corner opposite the constrained edge and vertex.
structuralBoundaryLoad(modelD , 'Vertex' , 5 , ...
                              'Force' , [0,0,10] , ...
                              'Frequency' , 7600 );

% Specify the zero initial displacement and velocity.
structuralIC(modelD , 'Velocity' , [0;0;0] , 'Displacement' , [0;0;0]);

%Specify the relative and absolute tolerances for the solver.
modelD.SolverOptions.RelativeTolerance = 1E-5;
modelD.SolverOptions.AbsoluteTolerance = 1E-9;

% Solve the model using the default direct integration method.
%tlist = linspace(0 , 0.004 , 120);
tlist = linspace(0 , 0.005 , 200);
Rd = solve(modelD , tlist)

% Now, solve the model using the modal results.
%tlist = linspace(0,0.004,120);
Rdm = solve(modelD , tlist , 'ModalResults' , Rm)

%Interpolate the displacement at the center of the beam.
intrpUd = interpolateDisplacement( Rd , 0 , 0 , 0.0015 );
intrpUdm = interpolateDisplacement(Rdm , 0 , 0 , 0.0015 );

% Compare the direct integration results with the results obtained by modal superposition.
%plot(Rd.SolutionTimes , intrpUd.uz , 'BusyAction','cancel' )
figure(2)
plot(Rd.SolutionTimes , intrpUd.uz , '--b' , 'LineWidth' , 2 )
hold on
plot(Rdm.SolutionTimes , intrpUdm.uz , '--r' , 'LineWidth' , 2)
grid on
legend('Direct integration', 'Modal superposition')
xlabel('Time');
ylabel('Center of beam displacement')




