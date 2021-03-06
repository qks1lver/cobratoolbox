% The COBRAToolbox: testSolveCobraLP.m
%
% Purpose:
%     - testSolveCobraLP tests the SolveCobraLP function and its different methods
%
% Author:
%     - CI integration: Laurent Heirendt, February 2017
%
% Note:
%       test is performed on objective as solution can vary between machines, solver version etc..

% define global paths
global path_TOMLAB
global path_ILOG_CPLEX
global path_GUROBI

% save the current path
currentDir = pwd;

% initialize the test
initTest(fileparts(which(mfilename)));

% Dummy Model
% http://www2.isye.gatech.edu/~spyros/LP/node2.html
LPproblem.c = [200; 400];
LPproblem.A = [1 / 40, 1 / 60; 1 / 50, 1 / 50];
LPproblem.b = [1; 1];
LPproblem.lb = [0; 0];
LPproblem.ub = [1; 1];
LPproblem.osense = -1;
LPproblem.csense = ['L'; 'L'];

% set the tolerance
tol = 1e-4;

% test solver packages
solverPkgs = {'cplex_direct', 'tomlab_cplex', 'gurobi6', 'glpk'};

% list of tests
testSuite = {'dummyModel', 'ecoli'};

for k = 1:length(solverPkgs)

    % add the solver paths (temporary addition for CI)
    if strcmp(solverPkgs{k}, 'tomlab_cplex')
        addpath(genpath(path_TOMLAB));
    elseif strcmp(solverPkgs{k}, 'cplex_direct')
        addpath(genpath(path_ILOG_CPLEX));
    elseif strcmp(solverPkgs{k}, 'gurobi6')
        addpath(genpath(path_GUROBI));
    end

    if ~verLessThan('matlab', '8') && strcmp(solverPkgs{k}, 'cplex_direct')  % 2015
        fprintf(['\n IBM ILOG CPLEX - ', solverPkgs{k}, ' - is incompatible with this version of MATLAB, please downgrade or change solver\n'])
    else
        % change the COBRA solver (LP)
        solverOK = changeCobraSolver(solverPkgs{k});

        if solverOK == 1
            for p = 1:length(testSuite)
                fprintf('   Running %s with solveCobraLP using %s ... ', testSuite{p}, solverPkgs{k});

                if p == 1
                    % solve LP problem printing summary information
                    for printLevel = 0:3
                        LPsolution = solveCobraLP(LPproblem, 'printLevel', printLevel);
                    end

                    for i = 1:length(LPsolution.full)
                        assert((abs(LPsolution.full(i) - 1) < tol))
                    end
                    assert(abs(LPsolution.obj) - 600 < tol)

                elseif p == 2
                    % solve th ecoli_core_model (csense vector is missing)
                    load('ecoli_core_model', 'model');

                    % solveCobraLP
                    solution_solveCobraLP = solveCobraLP(model);

                    % optimizeCbModel
                    solution_optimizeCbModel = optimizeCbModel(model);

                    % compare both solution objects
                    assert(solution_solveCobraLP.obj == solution_optimizeCbModel.f)
                    assert(isequal(solution_solveCobraLP.full, solution_optimizeCbModel.x))
                    assert(isequal(solution_solveCobraLP.rcost, solution_optimizeCbModel.w))
                    assert(isequal(solution_solveCobraLP.dual, solution_optimizeCbModel.y))
                    assert(solution_solveCobraLP.stat == solution_optimizeCbModel.stat)
                end

                % output a success message
                fprintf('Done.\n');
            end
        end
    end

    % remove the solver paths (temporary addition for CI)
    if strcmp(solverPkgs{k}, 'tomlab_cplex')
        rmpath(genpath(path_TOMLAB));
    elseif strcmp(solverPkgs{k}, 'cplex_direct')
        rmpath(genpath(path_ILOG_CPLEX));
    elseif strcmp(solverPkgs{k}, 'gurobi6')
        rmpath(genpath(path_GUROBI));
    end
end

% change the directory
cd(currentDir)
