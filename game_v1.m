function SynapseCatcher_Audio()
% =========================================================================
% SYNAPSE CATCHER - Synaptic transmission simulation (Octave/MATLAB)
% Controls: UP / DOWN arrows (move), SPACE (pause/start), ESC (quit)
% =========================================================================
% Names and contribution : Lou URSINI 33% , Margaux BARTON 33%, Clarisse COUDERC 33%
%
% Game context:
%   This game represents a chemical synapse. The pre-synaptic
%   terminal releases neurotransmitters into the synaptic cleft. The
%   player controls the post-synaptic membrane and its receptors.
% Goal:
%   Catch the correct neurotransmitters with the matching post-synaptic
%   receptors while avoiding neurotoxins.
%
% Main game components:
%   - Pre-synaptic terminal
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
% Sources used:
%   - Audio is generated procedurally in Octave; no external sound files are required.
%   - AI : Gemini, ChatGPT
%   - All graphics are drawn directly with GNU Octave plotting functions.
%
% Software:
%   GNU Octave 11.3
%   Code version: 3.0
%   Date: 2026-10-08 (YYYY-MM-DD).
%
% Rubric features deliberately implemented:
%   1. Detailed rules screen and on-screen instructions.
%   2. Movement is explained
%   3. Levels can be replayed after failure while lives remain.
%   4. SPACE pauses/resumes the active game and the background music.
%   5. Original graphical synapse, receptors, molecules and action-potential plot.
%   6. The figure is resizable and the axes remain in a stable game coordinate system.
%   7. dt uses elapsed real time, so movement and particle speed adapt to frame rate.
%   8. Success, failure and final game-over/victory scenarios are possible.
%  10. Difficulty starts simple and increases over six levels.
%  12. Rules, level intros, gameplay, results and final screens are separated.
%  13. Randomized molecule type, position, speed and advanced double-spawns
%      make replays different.
%  14. Positive capture sound, toxin warning sound, level-up jingle and fun
%      background music improve feedback and replay experience.
%
% =========================================================================
clc;

% --- 1. GLOBAL PARAMETERS & GAME STATE ---

NLEVELS = 6;
LEVEL_TIME = 40;
W = 100; H = 60;
target = [20 35 55 80 110 145]; % required points per level
toxinLimit = 3;

score = 0;
lives = 2;
level = 1;
quitGame = false;
paused = false;

% Controlled post-synaptic synapse - timing and interface control
playerY = H/2;
keyDirection = 0; % 1: up, -1: down
playerSpeed = 20.0;

% --- 2. WINDOW SETUP / PRESENTATION OF THE INTERFACE ---
fig = figure('Name', 'Synapse Catcher', 'NumberTitle', 'off', ...
    'Color', [0.035 0.045 0.08], 'MenuBar', 'none', 'ToolBar', 'none', ...
    'KeyPressFcn', @keyDown, 'WindowKeyReleaseFcn', @keyUp, ...
    'CloseRequestFcn', @closeGame, 'Position', [100 80 1100 700]);

ax = axes('Parent', fig, 'Position', [0.04 0.08 0.92 0.84], ...
    'Color', [0.02 0.025 0.055]);
axis(ax, [0 W 0 H], 'manual', 'off');

% --- 3. ADDING AUDIO ENGINE (procedural synthesis) ---
audioEnabled = false;
try
    fs = 22050;
    capturePlayer = audioplayer(makeTone([523 659 784], [0.1 0.12 0.16], fs, 0.35), fs);
    toxinPlayer   = audioplayer(makeTone([220 165 110], [0.12 0.16 0.24], fs, 0.38), fs);
    levelPlayer   = audioplayer(makeTone([523 659 784 1046], [0.12 0.12 0.12 0.25], fs, 0.32), fs);
    bgPlayer      = audioplayer(makeBackgroundMusic(fs, 42), fs);
    audioEnabled  = true;
catch
    % Silent fallback if audio output is unavailable
end

% Title and rules screen
showRules();
if quitGame, return; end

% =========================================================================
% --- 4. MAIN LOOP ---
% =========================================================================
while level <= NLEVELS && ~quitGame && lives > 0
    % Level reset
    playerY = max(9, min(H-9, playerY));
    toxinsCaught = 0;
    levelScore = 0;
    particles = struct('x',{},'y',{},'type',{},'speed',{},'size',{});

    showLevelIntro(level);
    if quitGame, break; end

    if audioEnabled
        try stop(bgPlayer); play(bgPlayer); catch, end
    end

% initiation of the variables
    t0 = tic;
    lastT = 0;
    spawnClock = 0;
    toxinClock = 0;
    flashClock = 0;
    flashText = '';

    % --- Frame loop (40s per trial) ---
    while toc(t0) < LEVEL_TIME && ~quitGame
        if ~ishandle(fig), quitGame = true; break; end

        % Pause handling
        if paused
            if audioEnabled, try pause(bgPlayer); catch, end; end
            drawScene(particles, levelScore, toxinsCaught, LEVEL_TIME-toc(t0), level, 'PAUSED - press SPACE to resume', 1);
            drawnow; pause(0.05);
            continue;
        elseif audioEnabled
            try resume(bgPlayer); catch, end
        end

        % Delta time for framerate-independent speed
        curT = toc(t0);
        dt = min(curT - lastT, 0.1);
        lastT = curT;

        % Move synapse
        playerY = max(9, min(H-9, playerY + playerSpeed * keyDirection * dt));

        % Progressive difficulty settinggs
        baseSpawn = max(1.15 - 0.15*level, 0.35);
        speedMin = 12 + 2.2 * (level - 1);
        speedMax = 12 + 2.8 * (level - 1);

        spawnClock = spawnClock + dt;
        toxinClock = toxinClock + dt;

        % Neurotransmitter release (Glutamate = 1, GABA = 2)
        if spawnClock >= baseSpawn
            spawnClock = 0;
            particles(end+1) = newParticle(randi(2), speedMin, speedMax, 1.25);
            % Random double release on higher levels
            if level >= 5 && rand() < 0.15
                particles(end+1) = newParticle(randi(2), speedMin, speedMax, 1.15);
            end
        end

        % Neurotoxin release starting only at level 2 (Toxin = 3)
        toxinInterval = max(4.8 - 0.55*(level-2), 1.5);
        if level >= 2 && toxinClock >= toxinInterval
            toxinClock = 0;
            particles(end+1) = newParticle(3, speedMin + 1, speedMin + 4, 1.45);
        end

        % Particle movement and collision controol
        keep = true(1, numel(particles));
        ch1Y = playerY + 4.9; % Glutamate channel
        ch2Y = playerY - 4.9; % GABA channel

        for k = 1:numel(particles)
            particles(k).x = particles(k).x + particles(k).speed * dt;

            % Check collision with post-synaptic receptors
            if particles(k).x >= 76 && particles(k).x <= 87
                hit = false;
                if particles(k).type == 1 && abs(particles(k).y - ch1Y) < 3.0
                    levelScore = levelScore + 10; score = score + 10;
                    flashText = '+10 GLUTAMATE CAPTURED!'; hit = true;
                    playSnd(capturePlayer);
                elseif particles(k).type == 2 && abs(particles(k).y - ch2Y) < 3.0
                    levelScore = levelScore + 10; score = score + 10;
                    flashText = '+10 GABA CAPTURED!'; hit = true;
                    playSnd(capturePlayer);
                elseif particles(k).type == 3 && abs(particles(k).y - playerY) < 7.5
                    levelScore = max(0, levelScore - 25); score = max(0, score - 25);
                    toxinsCaught = toxinsCaught + 1;
                    flashText = '-25 NEUROTOXIN!'; hit = true;
                    playSnd(toxinPlayer);
                end

                if hit
                    keep(k) = false;
                    flashClock = 0.3 + 0.5*(particles(k).type == 3);
                    if toxinsCaught >= toxinLimit, break; end
                end
            end

            % Discard off-screen particles
            if particles(k).x > W + 3, keep(k) = false; end
        end

        if toxinsCaught >= toxinLimit, break; end
        if ~isempty(particles), particles = particles(keep); end
        if flashClock > 0, flashClock = flashClock - dt; end

        % Render scene
        drawScene(particles, levelScore, toxinsCaught, max(0, LEVEL_TIME-toc(t0)), level, flashText, flashClock);
        drawnow; pause(0.018);
    end

    if quitGame, break; end

    % --- 5. LEVEL OUTCOME/after each level ---
    success = (levelScore >= target(level)) && (toxinsCaught < toxinLimit);
    if success
        lives = lives + 1;
        if audioEnabled, try stop(bgPlayer); play(levelPlayer); catch, end; end
        showLevelResult(level, true, levelScore, target(level), toxinsCaught, score, lives);
        level = level + 1;
    else
        lives = lives - 1;
        if audioEnabled, try stop(bgPlayer); catch, end; end
        showLevelResult(level, false, levelScore, target(level), toxinsCaught, score, lives);
    end
end

% Final game screen
if audioEnabled, try stop(bgPlayer); catch, end; end
if ~quitGame, showEndScreen(level > NLEVELS); end


% =========================================================================
% --- 6. DISPLAY & SCREEN RENDERING ---
% =========================================================================

    function resetScreen()
        cla(ax); axis(ax, [0 100 0 60], 'off');
    end

    function showRules() % 1/ showing the rules at the start of the game and 2/ before each new level
        resetScreen();
        text(50, 53, 'Synapse Catcher', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 28, 'FontWeight', 'bold', 'Color', [0.85 0.95 1]);
        text(50, 44, 'GAME OBJECTIVE', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 15, 'FontWeight', 'bold', 'Color', [1 0.9 0.3]);
        text(50, 39, 'Catch neurotransmitters with matching receptors (UP / DOWN arrows)', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'white');

        % Legend shapes
        rectangle('Parent', ax, 'Position', [18 26 8 8], 'Curvature', [1 1], 'FaceColor', [0.1 0.55 1], 'EdgeColor', 'w');
        text(30, 30, 'GLUTAMATE (Blue circle) -> Glutamate receptor (+10 pts)', 'Parent', ax, 'FontSize', 11, 'Color', [0.3 0.7 1]);

        rectangle('Parent', ax, 'Position', [18 18 8 5], 'FaceColor', [0.2 0.9 0.35], 'EdgeColor', 'w');
        text(30, 20.5, 'GABA (Green square) -> GABA receptor (+10 pts)', 'Parent', ax, 'FontSize', 11, 'Color', [0.3 1 0.4]);

        patch('Parent', ax, 'XData', [22 18 26], 'YData', [14 7 7], 'FaceColor', [0.95 0.12 0.18], 'EdgeColor', 'w');
        text(30, 10, 'NEUROTOXIN (Red triangle) -> AVOID! (-25 pts, max 3 hits)', 'Parent', ax, 'FontSize', 11, 'Color', [1 0.3 0.3]);

        text(50, 2.5, 'SPACE: Start / Pause  |  ESC: Quit', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.65 0.7 0.8]);
        waitForSpace();
    end

    function showLevelIntro(L)
        resetScreen();
        msgs = { ...
            'Level 1: Slow release, get used to the receptors.', ...
            'Level 2: Neurotoxins appear! Stay alert.', ...
            'Level 3: Neurotransmitters move faster.', ...
            'Level 4: Higher traffic, watch out for crossing paths.', ...
            'Level 5: Fast pace, requires sharp reflexes.', ...
            'FINAL LEVEL: Maximum synaptic activity!'};

        text(50, 38, sprintf('LEVEL %d / %d', L, NLEVELS), 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 26, 'FontWeight', 'bold', 'Color', [0.85 0.95 1]);
        text(50, 30, sprintf('Goal: %d pts in %d s', target(L), LEVEL_TIME), 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 15, 'Color', [1 0.9 0.3]);
        text(50, 23, msgs{L}, 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'white');
        text(50, 12, 'Press SPACE to start', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.4 1 0.7]);
        waitForSpace();
    end

    function drawScene(P, LS, TC, timeLeft, L, msg, flash)
        cla(ax); hold(ax, 'on'); axis(ax, [0 W 0 H], 'off');

        % Top HUD
        text(2, 57, sprintf('LVL %d/%d', L, NLEVELS), 'Parent', ax, 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
        text(20, 57, sprintf('Score: %d / %d', LS, target(L)), 'Parent', ax, 'FontSize', 11, 'Color', [1 0.9 0.3]);
        text(50, 57, sprintf('Total: %d', score), 'Parent', ax, 'FontSize', 11, 'Color', [0.5 0.9 1]);
        text(72, 57, sprintf('Lives: %d', lives), 'Parent', ax, 'FontSize', 11, 'Color', [1 0.55 0.65]);
        text(87, 57, sprintf('Time: %04.1fs', timeLeft), 'Parent', ax, 'FontSize', 11, 'Color', [0.75 0.8 0.9]);
        text(80, 53, sprintf('Toxins: %d/%d', TC, toxinLimit), 'Parent', ax, 'FontSize', 10, 'Color', [1 0.35 0.35]);

        % Dimensions of pre-synaptic terminal & cleft
        rectangle('Parent', ax, 'Position', [13 7 7 43], 'Curvature', [0.2 0.2], 'FaceColor', [0.18 0.2 0.32], 'EdgeColor', [0.5 0.55 0.8], 'LineWidth', 1.5);
        rectangle('Parent', ax, 'Position', [20 7 55 43], 'FaceColor', [0.03 0.04 0.075], 'EdgeColor', [0.12 0.15 0.25], 'LineStyle', '--');
        for yy = 12:6:45
            plot(16.5, yy, 'o', 'MarkerSize', 6, 'MarkerFaceColor', [0.35 0.4 0.6], 'MarkerEdgeColor', [0.65 0.7 0.9]);
        end

        % Dim post-synaptic membrane
        th = linspace(-pi/2, pi/2, 40);
        patch('Parent', ax, 'XData', [81.5 + 4.5*cos(th), 81.5], 'YData', [playerY + 7.5*sin(th), playerY], ...
            'FaceColor', [0.13 0.16 0.25], 'EdgeColor', [0.7 0.8 1], 'LineWidth', 2);

        % Glu (top) and GABA (bottom) receptors
        rectangle('Parent', ax, 'Position', [80.2 playerY+2.4 6 5], 'Curvature', [0.4 0.4], 'FaceColor', [0.05 0.3 0.75], 'EdgeColor', [0.3 0.75 1], 'LineWidth', 1.5);
        rectangle('Parent', ax, 'Position', [80.2 playerY-7.4 6 5], 'Curvature', [0.4 0.4], 'FaceColor', [0.08 0.55 0.18], 'EdgeColor', [0.35 1 0.45], 'LineWidth', 1.5);
        text(87, playerY+4.8, 'GLU', 'Parent', ax, 'FontSize', 7, 'Color', [0.3 0.75 1]);
        text(87, playerY-5.2, 'GABA', 'Parent', ax, 'FontSize', 7, 'Color', [0.35 1 0.45]);

        % Molecules (glutamate, GABA, toxxin)
        for k = 1:numel(P)
            if P(k).type == 1
                plot(P(k).x, P(k).y, 'o', 'MarkerSize', P(k).size*8, 'MarkerFaceColor', [0.1 0.55 1], 'MarkerEdgeColor', [0.7 0.9 1]);
            elseif P(k).type == 2
                plot(P(k).x, P(k).y, 's', 'MarkerSize', P(k).size*7, 'MarkerFaceColor', [0.15 0.9 0.3], 'MarkerEdgeColor', [0.75 1 0.8]);
            else
                patch('Parent', ax, 'XData', [P(k).x P(k).x-1.5 P(k).x+1.5], 'YData', [P(k).y+1.7 P(k).y-1.2 P(k).y-1.2], ...
                    'FaceColor', [0.95 0.08 0.12], 'EdgeColor', [1 0.55 0.55]);
            end
        end

        % Hit feedback text
        if nargin >= 7 && flash > 0 && ~isempty(msg)
            text(50, 50, msg, 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [1 1 0.4]);
        end
        hold(ax, 'off');
    end

    function showLevelResult(L, ok, LS, need, TC, tot, remLives)
        resetScreen();
        if ok
            col = [0.3 1 0.55]; titleT = sprintf('LEVEL %d COMPLETE!', L);
            subT = sprintf('+1 life  |  Level score: %d / %d', LS, need);
        else
            col = [1 0.35 0.4]; titleT = sprintf('LEVEL %d FAILED', L);
            subT = sprintf(ternary(TC >= toxinLimit, 'Toxin limit reached (3 hits)!', 'Not enough points: %d / %d'), LS, need);
        end

        text(50, 42, titleT, 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 24, 'FontWeight', 'bold', 'Color', col);
        text(50, 34, subT, 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 13, 'Color', 'w');
        text(50, 27, sprintf('Total score: %d  |  Remaining lives: %d', tot, remLives), 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', [0.6 0.85 1]);

        drawnow;
        if ok, animatePA(); end % AP animation
        if remLives > 0
            text(50, 8, 'Press SPACE to continue', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold', 'Color', [0.4 1 0.7]);
            waitForSpace();
        end
    end

    function animatePA()
        % Educational action-potential voltage trace
        xv = [8 28 35 39 43 47 52 58 68 78 92];
        yv = [18 18 18 20 39 49 38 24 14 17 18];
        for a = 1:12
            if ~ishandle(fig) || quitGame, return; end
            resetScreen(); hold(ax, 'on');
            text(50, 52, 'ACTION POTENTIAL GENERATED', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.8 0.9 1]);
            plot(xv, yv, 'LineWidth', 2.5, 'Color', [0.2 0.85 1]);
            idx = min(a, length(xv));
            plot(xv(idx), yv(idx), 'o', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.85 0.15], 'MarkerEdgeColor', 'w');
            text(20, 10, 'REST', 'Color', 'w'); text(43, 10, 'DEPOLARIZATION', 'Color', 'w'); text(65, 10, 'REPOLARIZATION', 'Color', 'w');
            text(50, 4, 'Na+ influx -> Depolarization  |  K+ efflux -> Repolarization', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', [0.7 0.8 0.9]);
            hold(ax, 'off'); drawnow; pause(0.1);
        end
    end

    function showEndScreen(won)
        resetScreen();
        if won
            text(50, 42, 'VICTORY!', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 30, 'FontWeight', 'bold', 'Color', [0.3 1 0.55]);
            text(50, 34, 'You completed all synaptic levels.', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'w');
        else
            text(50, 40, 'GAME OVER', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 30, 'FontWeight', 'bold', 'Color', [1 0.3 0.35]);
            text(50, 32, 'All lives have been used.', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'w');
        end
        text(50, 24, sprintf('FINAL SCORE: %d', score), 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 20, 'FontWeight', 'bold', 'Color', [1 0.9 0.3]);
        text(50, 10, 'Press ESC to quit.', 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.7 0.75 0.85]);
        drawnow;
    end


% =========================================================================
% --- 7. HELPERS & PROCEDURAL AUDIO ---
% =========================================================================
% different functions for the audio : different songs

    function p = newParticle(t, sMin, sMax, sz)
        p.x = 22; p.y = 7 + rand()*(H-14);
        p.type = t;
        p.speed = sMin + rand()*(sMax - sMin);
        p.size = sz;
    end

    function playSnd(snd)
        if audioEnabled, try play(snd); catch, end; end
    end

    function waitForSpace()
        setappdata(fig, 'startGame', false); drawnow;
        while ishandle(fig) && ~getappdata(fig, 'startGame') && ~quitGame
            drawnow; pause(0.05);
        end
    end

    function res = ternary(cond, a, b)
        if cond, res = a; else, res = b; end
    end

    function y = makeTone(freqs, durs, fs, amp)
        y = [];
        for i = 1:numel(freqs)
            n = round(durs(i)*fs); tt = (0:n-1)/fs;
            env = min(1, tt/0.015) .* min(1, (n-1-tt*fs+1)/(0.04*fs));
            y = [y, amp * sin(2*pi*freqs(i)*tt) .* env]; %#ok<AGROW>
        end
        y = y(:);
    end

    function y = makeBackgroundMusic(fs, dur)
        notes = [261 329 392 523 392 329 293 349 440 587 440 349 261 329 392 659];
        bar = [];
        for i = 1:numel(notes)
            n = round(0.28*fs); tt = (0:n-1)/fs;
            env = min(1, tt/0.02) .* min(1, (n-1-tt*fs+1)/(0.06*fs));
            lead = 0.05 * sin(2*pi*notes(i)*tt);
            bass = 0.02 * sin(pi*notes(i)*tt);
            bar = [bar, (lead + bass) .* env]; %#ok<AGROW>
        end
        y = repmat(bar, 1, ceil(dur/(numel(bar)/fs)));
        y = y(1:round(dur*fs))';
    end

% --- 8. KEYBOARD CALLBACKS ---
% how to use the arrow and mouvement
    function keyDown(~, ev)
        k = lower(ev.Key);
        switch k
            case {'uparrow', 'up'}, keyDirection = 1;
            case {'downarrow', 'down'}, keyDirection = -1;
            case {'space', 'spacebar'}
                if isappdata(fig, 'startGame') && ~getappdata(fig, 'startGame')
                    setappdata(fig, 'startGame', true); paused = false;
                else
                    paused = ~paused;
                end
            case {'escape', 'esc'}, quitGame = true; closeGame();
        end
    end

    function keyUp(~, ev)
        if ismember(lower(ev.Key), {'uparrow', 'up', 'downarrow', 'down'})
            keyDirection = 0; % Stop moving on key release
        end
    end

    function closeGame(~, ~)
        quitGame = true;
        if audioEnabled, try stop(bgPlayer); catch, end; end
        if ishandle(fig), delete(fig); end
    end
end
