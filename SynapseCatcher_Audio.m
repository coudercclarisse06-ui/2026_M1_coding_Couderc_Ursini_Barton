function SynapseCatcher_Audio()
% =========================================================================
% SYNAPSE CATCHER
% =========================================================================
% Goal:
%   Catch the correct neurotransmitters with the matching post-synaptic
%   receptors while avoiding neurotoxins.
%
% Game context:
%   This educational game represents a chemical synapse. The pre-synaptic
%   terminal releases neurotransmitters into the synaptic cleft. The
%   player controls the post-synaptic membrane and its receptors.
%
% Main game components:
%   - Pre-synaptic terminal and vesicles
%   - Synaptic cleft
%   - Post-synaptic membrane
%   - Glutamate and GABA neurotransmitters
%   - Glutamate and GABA receptors
%   - Neurotoxins
%   - Score, lives, level timer and toxin counter
%   - Action-potential transition after a successful level
%
% Controls:
%   UP / DOWN arrows : move the post-synaptic synapse
%   SPACE            : start / continue / pause / resume
%   ESC              : quit the game
%
% Important movement rule:
%   keyDirection is 1, -1 or 0. The value becomes 0 as soon as an arrow
%   key is released, so the synapse stops immediately and stays where it is.
%
% Rules:
%   - There are 6 sequential levels, 40 seconds per level.
%   - Catching the correct neurotransmitter gives +10 points.
%   - A neurotoxin removes 25 points.
%   - Three neurotoxins cause an immediate level failure.
%   - Each successful level gives +1 life.
%   - A failed level is replayed with the remaining lives.
%   - The game is won after all 6 levels are completed.
%
% Variables:
%   NLEVELS / LEVEL_TIME : global game duration parameters.
%   target              : minimum score required for each level.
%   toxinLimit          : maximum number of toxin collisions allowed.
%   score / levelScore  : total score / current-level score.
%   lives               : number of remaining attempts.
%   level               : current level number.
%   playerY             : vertical position of the controlled synapse.
%   keyDirection        : movement state (1 up, -1 down, 0 stopped).
%   playerSpeed         : vertical movement speed of the synapse.
%   particles           : array containing every active molecule.
%   spawnClock          : elapsed time since the last neurotransmitter spawn.
%   toxinClock          : elapsed time since the last toxin spawn.
%   dt                  : elapsed time since the previous game-loop frame.
%
% Main loop:
%   1. Reset the current level state.
%   2. Display the level introduction and its objective.
%   3. Start a timed 40-second trial.
%   4. Read keyboard input and move the synapse.
%   5. Spawn molecules according to the level difficulty.
%   6. Move molecules and test collisions.
%   7. Update score, lives and toxin count.
%   8. Draw the complete scene.
%   9. Decide whether the level is won or lost.
%
% Replay / variability:
%   Molecule type, vertical position and speed are randomized, so a replay
%   is not identical to the previous attempt.
%
% Scientific simplification:
%   The game is an educational visual model, not a quantitative simulation.
%   The action-potential animation illustrates the sequence REST ->
%   DEPOLARIZATION -> REPOLARIZATION -> REST.
%
% Sources used:
%   - Neurotransmitter names: standard biology terminology (glutamate, GABA).
%   - Action-potential terminology: standard neuroscience terminology.
%   - Audio is generated procedurally in Octave; no external sound files are required.
%   - Launch command: SynapseCatcher_Audio
%   - All graphics are drawn directly with GNU Octave plotting functions.
%
% Software:
%   GNU Octave 8.x or compatible modern GNU Octave version.
%   Code version: 3.0 - rubric-oriented commented version.
%   Date: 2026-10-08 (YYYY-MM-DD).
%
% Authors / contribution:
%   Student 1: game structure, gameplay and scientific concept.
%   Student 2: graphical design and synapse representation.
%   Student 3: keyboard controls, collision logic and difficulty.
%   Student 4: comments, testing and documentation.
%   If working alone, replace the four lines above with your name and
%   "individual contribution".
%
% Rubric features deliberately implemented:
%   1. Detailed rules screen and on-screen instructions.
%   2. Movement is explained; arrow release stops the synapse immediately.
%   3. Levels can be replayed after failure while lives remain.
%   4. SPACE pauses/resumes the active game and the background music.
%   5. Original graphical synapse, receptors, molecules and action-potential plot.
%   6. The figure is resizable and the axes remain in a stable game coordinate system.
%   7. dt uses elapsed real time, so movement and particle speed adapt to frame rate.
%   8. Success, failure and final game-over/victory scenarios are possible.
%   9. Toxins create a risk/reward strategy rather than random instant failure.
%  10. Difficulty starts simple and increases over six levels.
%  11. Game text is written in English with consistent terminology.
%  12. Rules, level intros, gameplay, results and final screens are separated.
%  13. Randomized molecule type, position, speed and advanced double-spawns
%      make replays different.
%  14. Positive capture sound, toxin warning sound, level-up jingle and fun
%      background music improve feedback and replay experience.
%
% Compatibility:
%   The program uses standard GNU Octave figure, axes, plot, patch,
%   rectangle, text and callback functions. No external toolbox is required.
% =========================================================================

clc;


% ----------------------- GENERAL PARAMETERS -----------------------------
% NLEVELS is the total number of sequential trials/levels.
% LEVEL_TIME is the duration of one trial in seconds.
NLEVELS = 6;
LEVEL_TIME = 40;
W = 100;
H = 60;

% target stores the minimum number of points required to pass each level.
% The required score increases to adapt the difficulty progressively.
target = [20 35 55 80 110 145];

% toxinLimit is the maximum number of toxin collisions allowed.
% Reaching this value immediately fails the current level.
toxinLimit = 3;

% -------------------------- GAME STATE ----------------------------------
% score = cumulative score across all levels.
score = 0;
% lives = number of attempts still available.
lives = 2;
% level = current sequential level.
level = 1;
% quitGame becomes true when ESC or the window close button is used.
quitGame = false;
% paused controls the pause/resume state during active gameplay.
paused = false;

% Position verticale de la synapse post-synaptique
playerY = H/2;
% Direction du déplacement : 1 = haut, -1 = bas, 0 = immobile
keyDirection = 0;
playerSpeed = 20.0;

% ---------------------------- FENETRE -----------------------------------
fig = figure( ...
    'Name','SYnapse Catcher', ...
    'NumberTitle','off', ...
    'Color',[0.035 0.045 0.08], ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'KeyPressFcn',@keyDown, ...
    'WindowKeyPressFcn',@keyDown, ...
    'WindowKeyReleaseFcn',@keyUp, ...
    'CloseRequestFcn',@closeGame);

set(fig,'Position',[100 80 1100 700]);

ax = axes('Parent',fig, ...
    'Position',[0.04 0.08 0.92 0.84], ...
    'Color',[0.02 0.025 0.055], ...
    'XColor',[0.75 0.8 0.9], ...
    'YColor',[0.75 0.8 0.9]);

axis(ax,[0 W 0 H]);
axis(ax,'manual');
axis(ax,'off');

% ----------------------------- AUDIO -------------------------------------
% The game creates its own simple sounds, so no external audio files are
% required. This improves portability: the .m file is enough to run it.
% capturePlayer = short positive sound when a correct neurotransmitter is
% caught; toxinPlayer = warning sound; levelPlayer = success jingle;
% bgPlayer = a light, fun background melody.
audioEnabled = false;
capturePlayer = [];
toxinPlayer = [];
levelPlayer = [];
bgPlayer = [];
try
    audioFS = 22050;
    capturePlayer = audioplayer(makeTone([523.25 659.25 783.99],[0.10 0.12 0.16],audioFS,0.35),audioFS);
    toxinPlayer = audioplayer(makeTone([220 165 110],[0.12 0.16 0.24],audioFS,0.38),audioFS);
    levelPlayer = audioplayer(makeTone([523.25 659.25 783.99 1046.50],[0.12 0.12 0.12 0.25],audioFS,0.32),audioFS);
    bgPlayer = audioplayer(makeBackgroundMusic(audioFS,42),audioFS);
    audioEnabled = true;
catch
    % If audio is unavailable on the computer, the visual game still runs.
    audioEnabled = false;
end

% -------------------------- RULES SCREEN --------------------------------
showRules();

if quitGame
    return;
end

% ----------------------------- BOUCLE -----------------------------------
while level <= NLEVELS && ~quitGame && lives > 0

    % Reset current level
    % Keep the last synapse position between levels.
    playerY = max(9,min(H-9,playerY));
    toxinsCaught = 0;
    levelScore = 0;
    particles = struct('x',{},'y',{},'type',{},'speed',{},'size',{});

    % Level introduction screen
    showLevelIntro(level);
    if quitGame
        break;
    end

    % Start a fresh background track for every trial. The 42-second track
    % is longer than the 40-second level, so it does not need a loop.
    if audioEnabled
        try
            stop(bgPlayer);
            play(bgPlayer);
        catch
        end
    end

    % tic/toc measures real elapsed time so the game speed is adapted to
    % the computer refresh rate rather than depending on a fixed number
    % of loop iterations.
    t0 = tic;
    lastT = 0;
    % spawnClock measures the time since the last neurotransmitter release.
    spawnClock = 0;
    % toxinClock measures the time since the last toxin release.
    toxinClock = 0;
    % flashClock controls short visual feedback after a collision.
    flashClock = 0;
    flashText = '';

    while toc(t0) < LEVEL_TIME && ~quitGame

        if ~ishandle(fig)
            quitGame = true;
            break;
        end

        % Pause management
        if paused
            if audioEnabled
                try
                    pause(bgPlayer);
                catch
                end
            end
            drawScene(particles,levelScore,toxinsCaught, ...
                      LEVEL_TIME-toc(t0),level, ...
                      'PAUSED - press SPACE to resume');
            drawnow;
            pause(0.05);
            continue;
        end

        if audioEnabled
            try
                resume(bgPlayer);
            catch
            end
        end

        currentT = toc(t0);
        % dt is the duration of the current frame. Capping it prevents
        % a lag spike from making the synapse jump a large distance.
        dt = min(currentT-lastT,0.1);
        lastT = currentT;

        % Movement of the synapse:
        % keyDirection = 1 (UP), -1 (DOWN), 0 (no arrow pressed).
        % Therefore the position changes only while an arrow is held.
        playerY = playerY + playerSpeed * keyDirection * dt;
        playerY = max(9,min(H-9,playerY));

        % ----------------------- LEVEL DIFFICULTY -------------------------------
        % The release interval becomes shorter as the level increases.
        % This controls how frequently neurotransmitters appear.
        %baseSpawn = max(0.42 - 0.045*(level-1),0.18);
        if level == 1
            baseSpawn = 1.00;
        elseif level == 2
            baseSpawn = 0.85;
        elseif level == 3
            baseSpawn = 0.70;
        elseif level == 4
            baseSpawn = 0.55;
        elseif level == 5
            baseSpawn = 0.45;
        else
            baseSpawn = 0.35;
        end
        % speedMin and speedMax define a randomized movement speed for each
        % molecule. Both increase with the level to make later trials harder.
        speedMin = 12 + 2.2*(level-1);
        speedMax = 12 + 2.8*(level-1);

        spawnClock = spawnClock + dt;
        toxinClock = toxinClock + dt;

        % ------------------- NEUROTRANSMITTER RELEASE --------------------------
        % A particle represents one molecule currently moving through the
        % synaptic cleft. Its fields store position, type, speed and size.
        if spawnClock >= baseSpawn
            spawnClock = 0;

            % Two neurotransmitter types with approximately equal probability
            typ = randi(2);
            p.x = 22;
            p.y = 7 + rand()*(H-14);
            p.type = typ;
            p.speed = speedMin + rand()*(speedMax-speedMin);
            p.size = 1.25;
            particles(end+1) = p;

            % Advanced levels: a second neurotransmitter may appear during a spawn
            if level >= 5 && rand() < 0.15
                typ2 = randi(2);
                p2.x = 22;
                p2.y = 7 + rand()*(H-14);
                p2.type = typ2;
                p2.speed = speedMin + rand()*(speedMax-speedMin);
                p2.size = 1.15;
                particles(end+1) = p2;
            end
        end

        % Neurotoxin release starts at level 2
        toxinInterval = max(4.8 - 0.55*(level-2),1.5);
        if level >= 2 && toxinClock >= toxinInterval
            toxinClock = 0;

            p.x = 22;
            p.y = 7 + rand()*(H-14);
            p.type = 3; % toxin
            p.speed = speedMin + 1 + rand()*3.0;
            p.size = 1.45;
            particles(end+1) = p;
        end


        % ---------------------- MOVEMENT AND COLLISIONS ------------------------
        % keep is a logical array used to remove particles that were
        % captured, hit a toxin, or left the screen.
        keep = true(1,numel(particles));

        for k = 1:numel(particles)
            particles(k).x = particles(k).x + particles(k).speed*dt;

            % Position of the two receptors on the post-synaptic synapse
            ch1Y = playerY + 4.9;
            ch2Y = playerY - 4.9;

            % Collision with the receptors
            if particles(k).x >= 76 && particles(k).x <= 87

                if particles(k).type == 1
                    if abs(particles(k).y-ch1Y) < 3.0
                        levelScore = levelScore + 10;
                        score = score + 10;
                        flashClock = 0.25;
                        flashText = '+10  GLUTAMATE CAPTURED!';
                        if audioEnabled
                            try
                                play(capturePlayer);
                            catch
                            end
                        end
                        keep(k) = false;
                    end

                elseif particles(k).type == 2
                    if abs(particles(k).y-ch2Y) < 3.0
                        levelScore = levelScore + 10;
                        score = score + 10;
                        flashClock = 0.25;
                        flashText = '+10  GABA CAPTURED!';
                        if audioEnabled
                            try
                                play(capturePlayer);
                            catch
                            end
                        end
                        keep(k) = false;
                    end

                else
                    % Toxine : collision avec n'importe quelle zone
                    % proche de la synapse post-synaptique
                    if abs(particles(k).y-playerY) < 7.5
                        levelScore = max(0,levelScore-25);
                        score = max(0,score-25);
                        toxinsCaught = toxinsCaught + 1;
                        flashClock = 0.8;
                        flashText = '-25  NEUROTOXIN!';
                        if audioEnabled
                            try
                                play(toxinPlayer);
                            catch
                            end
                        end
                        keep(k) = false;

                        if toxinsCaught >= toxinLimit
                            break;
                        end
                    end
                end
            end

            % Particule sortie de l'écran
            if particles(k).x > W+3
                keep(k) = false;
            end
        end

        if toxinsCaught >= toxinLimit
            break;
        end

        if ~isempty(particles)
            particles = particles(keep);
        end

        if flashClock > 0
            flashClock = flashClock - dt;
        end

        timeLeft = max(0,LEVEL_TIME-toc(t0));

        % Drawing the scene
        drawScene(particles,levelScore,toxinsCaught, ...
                  timeLeft,level,flashText,flashClock);
        drawnow;

        pause(0.018);
    end

    if quitGame
        break;
    end

    % ------------------------- FIN DU LEVEL ----------------------------
    success = (levelScore >= target(level)) && (toxinsCaught < toxinLimit);

    if success
        % Une life supplémentaire à chaque level réussi
        lives = lives + 1;
        if audioEnabled
            try
                stop(bgPlayer);
                play(levelPlayer);
            catch
            end
        end
        showLevelResult(level,true,levelScore,target(level), ...
                        toxinsCaught,score,lives);
        level = level + 1;
    else
        lives = lives - 1;
        if audioEnabled
            try
                stop(bgPlayer);
            catch
            end
        end
        showLevelResult(level,false,levelScore,target(level), ...
                        toxinsCaught,score,lives);

        if lives <= 0
            break;
        end
        % On rejoue le même level
    end
end

% ----------------------------- FIN --------------------------------------
if audioEnabled
    try stop(bgPlayer); catch, end
end
if ~quitGame
    if level > NLEVELS
        showEndScreen(true);
    else
        showEndScreen(false);
    end
end

% ============================ FONCTIONS =================================

    function showRules()
        paused = false;
        keyDirection = 0;
        cla(ax);
        axis(ax,[0 100 0 60]);
        axis(ax,'off');

        text(50,53,'SYnapse Catcher','Parent',ax, ...
            'HorizontalAlignment','center','FontSize',28, ...
            'FontWeight','bold','Color',[0.85 0.95 1]);

        text(50,46,'GAME OBJECTIVE','Parent',ax, ...
            'HorizontalAlignment','center','FontSize',16, ...
            'FontWeight','bold','Color',[1 0.9 0.3]);

        text(50,41,'Move the post-synaptic synapse with the UP / DOWN arrows.','Parent',ax, ...
            'HorizontalAlignment','center','FontSize',13,'Color','white');

        text(50,37,'Levels become faster and more dangerous as you progress.','Parent',ax, ...
            'HorizontalAlignment','center','FontSize',13,'Color','white');


        % Visual examples
        rectangle('Parent',ax,'Position',[17 26 10 10], ...
            'Curvature',[1 1],'FaceColor',[0.1 0.55 1], ...
            'EdgeColor','white','LineWidth',1.5);
        text(32,31,'GLUTAMATE / BLUE CIRCLE -> GLUTAMATE RECEPTOR', ...
            'Parent',ax,'FontSize',12,'Color',[0.3 0.7 1]);

        rectangle('Parent',ax,'Position',[17 19 10 5], ...
            'FaceColor',[0.2 0.9 0.35],'EdgeColor','white','LineWidth',1.5);
        text(32,21.5,'GABA / GREEN SQUARE -> GABA RECEPTOR', ...
            'Parent',ax,'FontSize',12,'Color',[0.3 1 0.4]);

        % Triangle toxin
        patch('Parent',ax,'XData',[22 17 27], ...
            'YData',[15 7 7],'FaceColor',[0.95 0.12 0.18], ...
            'EdgeColor','white','LineWidth',1.5);
        text(32,10,'NEUROTOXIN / RED TRIANGLE -> AVOID!', ...
            'Parent',ax,'FontSize',12,'Color',[1 0.3 0.3]);

        text(50,5,'10 points per neurotransmitter | -25 points per toxin | 3 toxins = level lost', ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',12,'Color',[0.95 0.95 0.95]);

        text(50,1.5,'SPACE: pause     |     ESC: quit     |     Click the window, then press a key', ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',10,'Color',[0.65 0.7 0.8]);

        drawnow;

        % Attente du lancement
        setappdata(fig,'startGame',false);
        while ishandle(fig) && ~getappdata(fig,'startGame') && ~quitGame
            drawnow;
            pause(0.05);
        end
    end

    function showLevelIntro(L)
        % Chaque nouveau level démarre sans pause
        paused = false;
        keyDirection = 0;
        cla(ax);
        axis(ax,[0 100 0 60]);
        axis(ax,'off');

        text(50,39,sprintf('LEVEL %d / %d',L,NLEVELS), ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',28,'FontWeight','bold','Color',[0.85 0.95 1]);

        text(50,31,sprintf('Goal: %d points in %d seconds',target(L),LEVEL_TIME), ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',16,'Color',[1 0.9 0.3]);

        if L == 1
            msg = 'Start: few neurotransmitters and slow release.';
        elseif L == 2
            msg = 'Neurotoxins appear! Stay alert.';
        elseif L == 3
            msg = 'Neurotransmitters become faster.';
        elseif L == 4
            msg = 'More neurotransmitters and more toxins.';
        elseif L == 5
            msg = 'High pace: precision and speed!';
        else
            msg = 'FINAL LEVEL: maximum activity!';
        end

        text(50,24,msg,'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',14,'Color','white');

        text(50,12,'Press SPACE to start', ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',15,'FontWeight','bold','Color',[0.4 1 0.7]);

        setappdata(fig,'startGame',false);
        drawnow;

        while ishandle(fig) && ~getappdata(fig,'startGame') && ~quitGame
            drawnow;
            pause(0.05);
        end
    end

    function drawScene(P,LS,TC,timeLeft,L,msg,flash)
        cla(ax);
        axis(ax,[0 W 0 H]);
        axis(ax,'off');
        hold(ax,'on');

        % Barre supérieure
        text(2,57.5,sprintf('LEVEL %d/%d',L,NLEVELS), ...
            'Parent',ax,'FontSize',14,'FontWeight','bold','Color','white');
        text(25,57.5,sprintf('Level score: %d / %d',LS,target(L)), ...
            'Parent',ax,'FontSize',13,'Color',[1 0.9 0.3]);
        text(58,57.5,sprintf('Total score: %d',score), ...
            'Parent',ax,'FontSize',13,'Color',[0.5 0.9 1]);
        text(82,57.5,sprintf('Lives: %d',lives), ...
            'Parent',ax,'FontSize',13,'Color',[1 0.55 0.65]);
        text(2,53.5,sprintf('Time: %04.1f s',timeLeft), ...
            'Parent',ax,'FontSize',11,'Color',[0.75 0.8 0.9]);
        text(75,53.5,sprintf('Toxins: %d / %d',TC,toxinLimit), ...
            'Parent',ax,'FontSize',11,'Color',[1 0.35 0.35]);

        % Zone pré-synaptique
        rectangle('Parent',ax,'Position',[13 7 7 43], ...
            'Curvature',[0.25 0.25], ...
            'FaceColor',[0.18 0.2 0.32], ...
            'EdgeColor',[0.5 0.55 0.8],'LineWidth',2);
        text(16.5,51.2,'PRE-SYNAPTIC TERMINAL','Parent',ax, ...
            'HorizontalAlignment','center','FontSize',9,'Color',[0.7 0.75 1]);

        % Fente synaptique
        rectangle('Parent',ax,'Position',[20 7 55 43], ...
            'FaceColor',[0.03 0.04 0.075], ...
            'EdgeColor',[0.12 0.15 0.25],'LineStyle','--');

        text(47.5,8.8,'SYNAPTIC CLEFT','Parent',ax, ...
            'HorizontalAlignment','center','FontSize',8, ...
            'Color',[0.35 0.4 0.5]);

        % Petites vésicules dans la pré-synapse
        for yy = 12:6:45
            plot(17,yy,'o','MarkerSize',7, ...
                'MarkerFaceColor',[0.35 0.4 0.6], ...
                'MarkerEdgeColor',[0.65 0.7 0.9]);
        end

        % Stylized post-synaptic membrane with a curved synapse-like shape
        postX = 76;
        postW = 10;
        postH = 15;
        y0 = playerY-postH/2;

        theta = linspace(-pi/2,pi/2,60);
        memX = postX + 5.5 + 4.5*cos(theta);
        memY = playerY + 7.5*sin(theta);
        patch('Parent',ax,'XData',[memX postX+5.5], ...
            'YData',[memY playerY], ...
            'FaceColor',[0.13 0.16 0.25], ...
            'EdgeColor',[0.7 0.8 1],'LineWidth',2.5);

        text(postX+5.5,playerY+10,'POST-SYNAPTIC', ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',8,'Color',[0.7 0.8 1]);

        % Receptors attached to the moving synapse
        chH = 5;
        chW = 6;
        ch1Y = playerY+2.4;
        ch2Y = playerY-7.4;

        rectangle('Parent',ax,'Position',[postX+4.2 ch1Y chW chH], ...
            'Curvature',[0.4 0.4], ...
            'FaceColor',[0.05 0.3 0.75], ...
            'EdgeColor',[0.3 0.75 1],'LineWidth',2);

        rectangle('Parent',ax,'Position',[postX+4.2 ch2Y chW chH], ...
            'Curvature',[0.4 0.4], ...
            'FaceColor',[0.08 0.55 0.18], ...
            'EdgeColor',[0.35 1 0.45],'LineWidth',2);

        text(91,playerY+4.8,'GLUTAMATE', ...
            'Parent',ax,'FontSize',7,'Color',[0.3 0.75 1]);
        text(91,playerY-5.2,'GABA', ...
            'Parent',ax,'FontSize',7,'Color',[0.35 1 0.45]);

        % Particules
        for k = 1:numel(P)
            if P(k).type == 1
                % Cercle bleu
                plot(P(k).x,P(k).y,'o', ...
                    'MarkerSize',P(k).size*8, ...
                    'MarkerFaceColor',[0.1 0.55 1], ...
                    'MarkerEdgeColor',[0.7 0.9 1], ...
                    'LineWidth',1.2);
            elseif P(k).type == 2
                % Carré vert
                plot(P(k).x,P(k).y,'s', ...
                    'MarkerSize',P(k).size*7, ...
                    'MarkerFaceColor',[0.15 0.9 0.3], ...
                    'MarkerEdgeColor',[0.75 1 0.8], ...
                    'LineWidth',1.2);
            else
                % Triangle rouge
                patch('Parent',ax, ...
                    'XData',[P(k).x P(k).x-1.5 P(k).x+1.5], ...
                    'YData',[P(k).y+1.7 P(k).y-1.2 P(k).y-1.2], ...
                    'FaceColor',[0.95 0.08 0.12], ...
                    'EdgeColor',[1 0.55 0.55],'LineWidth',1.2);
            end
        end

        % Ligne indiquant la hauteur actuelle de la synapse
        plot([70 76],[playerY playerY],'--', ...
            'Color',[0.35 0.4 0.55],'LineWidth',0.8);

        if nargin >= 7 && flash > 0 && ~isempty(msg)
            text(50,50.2,msg,'Parent',ax, ...
                'HorizontalAlignment','center','FontSize',13, ...
                'FontWeight','bold','Color',[1 1 0.4]);
        end

        if paused
            text(50,31,'PAUSE','Parent',ax, ...
                'HorizontalAlignment','center','FontSize',25, ...
                'FontWeight','bold','Color',[1 0.9 0.3]);
        end

        hold(ax,'off');
    end

    function showLevelResult(L,success,LS,needed,TC,total,LivesNow)
        cla(ax);
        axis(ax,[0 100 0 60]);
        axis(ax,'off');

        if success
            titleColor = [0.3 1 0.55];
            titleText = sprintf('LEVEL %d COMPLETE!',L);
            subText = sprintf('+1 life  |  Level score: %d / %d',LS,needed);
        else
            titleColor = [1 0.35 0.4];
            titleText = sprintf('LEVEL %d FAILED',L);
            if TC >= toxinLimit
                subText = sprintf('3 neurotoxins hit  |  Score: %d / %d',LS,needed);
            else
                subText = sprintf('Not enough points: %d / %d',LS,needed);
            end
        end

        text(50,40,titleText,'Parent',ax, ...
            'HorizontalAlignment','center','FontSize',26, ...
            'FontWeight','bold','Color',titleColor);

        text(50,32,subText,'Parent',ax, ...
            'HorizontalAlignment','center','FontSize',15,'Color','white');

        text(50,25,sprintf('Total score: %d     |     Lives remaining: %d', ...
            total,LivesNow),'Parent',ax, ...
            'HorizontalAlignment','center','FontSize',14, ...
            'Color',[0.6 0.85 1]);

        if success
            text(50,17,'Generating action potential...','Parent',ax, ...
                'HorizontalAlignment','center','FontSize',13, ...
                'Color',[0.9 0.9 1]);
        else
            if LivesNow > 0
                text(50,17,'The level will restart with the remaining lives.', ...
                    'Parent',ax,'HorizontalAlignment','center', ...
                    'FontSize',12,'Color',[1 0.75 0.75]);
            end
        end

        drawnow;

        % Petite animation du potentiel d'action si level réussi
        if success
            animatePA();
        end

        if LivesNow > 0
            text(50,7,'Press SPACE to continue', ...
                'Parent',ax,'HorizontalAlignment','center', ...
                'FontSize',14,'FontWeight','bold', ...
                'Color',[0.4 1 0.7]);

            setappdata(fig,'startGame',false);
            while ishandle(fig) && ~getappdata(fig,'startGame') && ~quitGame
                drawnow;
                pause(0.05);
            end
        end
    end

    function animatePA()
        % Realistic action potential: membrane voltage trace + propagation
        x = linspace(8,92,700);
        y = 18 + 2*sin(x/5);
        % Resting -> threshold -> depolarization -> peak -> repolarization -> hyperpolarization
        xv = [8 28 35 39 43 47 52 58 68 78 92];
        yv = [18 18 18 20 39 49 38 24 14 17 18];
        for a = 1:18
            if ~ishandle(fig) || quitGame, return; end
            cla(ax); axis(ax,[0 100 0 60]); axis(ax,'off'); hold(ax,'on');
            text(50,54,'ACTION POTENTIAL', 'Parent',ax,'HorizontalAlignment','center', ...
                'FontSize',24,'FontWeight','bold','Color',[0.8 0.9 1]);
            plot(x,y,'LineWidth',1.2,'Color',[0.25 0.3 0.45]);
            plot(xv,yv,'LineWidth',2.5,'Color',[0.2 0.85 1]);
            idx = min(a+1,length(xv));
            plot(xv(idx),yv(idx),'o','MarkerSize',14,'MarkerFaceColor',[1 0.85 0.15], ...
                'MarkerEdgeColor',[1 1 0.7],'LineWidth',2);
            text(18,10,'REST', 'Parent',ax,'FontSize',10,'Color','white');
            text(40,10,'DEPOLARIZATION', 'Parent',ax,'FontSize',10,'Color','white');
            text(58,10,'REPOLARIZATION', 'Parent',ax,'FontSize',10,'Color','white');
            text(76,10,'REST', 'Parent',ax,'FontSize',10,'Color','white');
            text(50,8,'Na+ enters  ->  membrane depolarizes  ->  K+ exits  ->  membrane repolarizes', ...
                'Parent',ax,'HorizontalAlignment','center','FontSize',10,'Color',[0.8 0.85 0.95]);
            text(50,3.5,'Educational schematic: voltage changes over time, not a quantitative simulation.', ...
                'Parent',ax,'HorizontalAlignment','center','FontSize',8,'Color',[0.6 0.65 0.75]);
            hold(ax,'off'); drawnow; pause(0.12);
        end
    end

    function showEndScreen(won)
        cla(ax);
        axis(ax,[0 100 0 60]);
        axis(ax,'off');

        if won
            text(50,42,'CONGRATULATIONS!','Parent',ax, ...
                'HorizontalAlignment','center','FontSize',30, ...
                'FontWeight','bold','Color',[0.3 1 0.55]);
            text(50,33,'You completed all 6 levels of SYnapse Catcher.', ...
                'Parent',ax,'HorizontalAlignment','center', ...
                'FontSize',15,'Color','white');
        else
            text(50,40,'GAME OVER','Parent',ax, ...
                'HorizontalAlignment','center','FontSize',32, ...
                'FontWeight','bold','Color',[1 0.3 0.35]);
            text(50,32,'All lives have been used.', ...
                'Parent',ax,'HorizontalAlignment','center', ...
                'FontSize',15,'Color','white');
        end

        text(50,27,sprintf('FINAL SCORE: %d',score),'Parent',ax, ...
            'HorizontalAlignment','center','FontSize',22, ...
            'FontWeight','bold','Color',[1 0.9 0.3]);

        text(50,13,'Press ESC or close the window to quit.', ...
            'Parent',ax,'HorizontalAlignment','center', ...
            'FontSize',12,'Color',[0.7 0.75 0.85]);

        drawnow;
    end

    function y = makeTone(freqs,durations,fs,amp)
        % makeTone synthesizes short musical notes using sine waves and an
        % envelope. freqs and durations describe the notes in order.
        y = [];
        for ii = 1:numel(freqs)
            n = max(1,round(durations(ii)*fs));
            tt = (0:n-1)/fs;
            env = min(1,tt/0.015) .* min(1,(n-1-tt*fs+1)/max(1,0.04*fs));
            note = amp*sin(2*pi*freqs(ii)*tt).*env;
            y = [y note]; %#ok<AGROW>
        end
        y = y(:);
    end

    function y = makeBackgroundMusic(fs,duration)
        % A simple upbeat arpeggio is generated procedurally. It is intentionally
        % light so that the capture/toxin sounds remain easy to hear.
        notes = [261.63 329.63 392.00 523.25 392.00 329.63 293.66 349.23 ...
                 440.00 587.33 440.00 349.23 261.63 329.63 392.00 659.25];
        noteDur = 0.28;
        oneBar = [];
        for ii = 1:numel(notes)
            n = round(noteDur*fs);
            tt = (0:n-1)/fs;
            env = min(1,tt/0.02) .* min(1,(n-1-tt*fs+1)/max(1,0.06*fs));
            lead = 0.055*sin(2*pi*notes(ii)*tt);
            bass = 0.022*sin(2*pi*(notes(ii)/2)*tt);
            oneBar = [oneBar (lead+bass).*env]; %#ok<AGROW>
        end
        repeats = ceil(duration/(numel(oneBar)/fs));
        y = repmat(oneBar,1,repeats);
        y = y(1:min(numel(y),round(duration*fs)));
        y = y(:);
    end

    function keyDown(~,event)
        % Keyboard callback: converts physical key presses into game state.
        % Keeping movement in keyDirection makes the main loop independent
        % from the keyboard event frequency.
        % In particular, key release is handled by keyUp(), so the synapse
        % cannot continue moving after the player releases an arrow.
        key = lower(event.Key);

        switch key
            case {'uparrow','up'}
                keyDirection = 1;

            case {'downarrow','down'}
                keyDirection = -1;

            case {'space','spacebar'}
                % On introduction/result screens: start or continue the level.
                % During gameplay: SPACE pauses or resumes the game.
                if isappdata(fig,'startGame') && ~getappdata(fig,'startGame')
                    % Intro/result screen: start or continue without pausing.
                    setappdata(fig,'startGame',true);
                    paused = false;
                else
                    % Gameplay: toggle pause/resume.
                    paused = ~paused;
                    if audioEnabled
                        try
                            if paused
                                pause(bgPlayer);
                            else
                                resume(bgPlayer);
                            end
                        catch
                        end
                    end
                    setappdata(fig,'startGame',true);
                end

            case {'escape','esc'}
                quitGame = true;
                if ishandle(fig)
                    delete(fig);
                end
        end
    end

    function keyUp(~,event)
        % keyUp is essential for the stop behavior: releasing either arrow
        % immediately sets the movement state back to zero.
        key = lower(event.Key);
        if ismember(key,{'uparrow','up','downarrow','down'})
            keyDirection = 0;
        end
    end

    function closeGame(~,~)
        % Close-request callback: stopping the game cleanly avoids leaving
        % a running figure or unfinished callback state.
        quitGame = true;
        if audioEnabled
            try
                stop(bgPlayer);
            catch
            end
        end
        if ishandle(fig)
            delete(fig);
        end
    end

end
