function synth_final
% SYNTH_FINAL (Fixed & Ultimate Edition)
% - Fixed all syntax errors (broken lines) from copy-paste
% - Removed toolbox dependency (works on basic MATLAB)
% - Professional Dark UI

    clc;

    %% ---------------- 1. Initialization ----------------
    ctrl.freq = 440;
    ctrl.wave = 'sine';
    ctrl.gate = 0;
    ctrl.stop_signal = 0;
    ctrl.song_choice = 1;
    ctrl.volume = 0.5;

    % ADSR Defaults [A, D, S, R]
    ctrl.adsr_default = [0.02, 0.10, 0.60, 0.10];
    ctrl.adsr = ctrl.adsr_default;

    assignin('base','synth_control',ctrl);

    if ~evalin('base','exist(''synth_state'',''var'')')
        s.phase = 0;
        s.prev_freq = 440;
        s.prev_wave = 'sine';
        s.prev_out = 0;
        s.env_level = 0;
        s.adsr_state = 0; % 0=Idle, 1=Att, 2=Dec, 3=Sus, 4=Rel
        assignin('base','synth_state',s);
    end

    %% ---------------- 2. GUI Design ----------------
    old_fig = findobj('Tag', 'SynthGUI');
    if ~isempty(old_fig), delete(old_fig); end

    % Colors
    c_bg = [0.10 0.10 0.10];
    c_pnl = [0.15 0.15 0.15];
    c_txt = [0.90 0.90 0.90];
    c_acc = [0.00 0.70 0.80];
    c_green = [0.00 0.50 0.30];
    c_red = [0.70 0.20 0.20];

    f = figure('Name', 'MATLAB Synth Studio', 'Tag', 'SynthGUI', ...
        'NumberTitle', 'off', 'MenuBar', 'none', ...
        'Color', c_bg, ...
        'Position', [100, 100, 1000, 650], ...
        'CloseRequestFcn', @close_app);

    % --- TOP: VISUALIZER ---
    pnl_vis = uipanel('Parent', f, 'Title', ' OSCILLOSCOPE ', ...
        'TitlePosition', 'centertop', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'Position', [0.02, 0.62, 0.96, 0.36], 'BorderType', 'line', ...
        'HighlightColor', [0.3 0.3 0.3]);

    ax = axes('Parent', pnl_vis, 'Units', 'normalized', ...
        'Position', [0.05, 0.15, 0.9, 0.8], ...
        'YLim', [-1.1 1.1], 'XLim', [1 150], ...
        'Color', [0 0 0], 'XColor', [0.5 0.5 0.5], 'YColor', [0.5 0.5 0.5]);
    
    hLine = plot(ax, zeros(1,2048), 'LineWidth', 2, 'Color', c_acc);
    grid(ax, 'on');

    % --- BOTTOM LEFT: OSCILLATOR ---
    pnl_osc = uipanel('Parent', f, 'Title', ' OSCILLATOR ', ...
        'TitlePosition', 'centertop', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'Position', [0.02, 0.32, 0.30, 0.28], 'BorderType', 'line', ...
        'HighlightColor', [0.3 0.3 0.3]);

    % Frequency Label
    uicontrol('Parent', pnl_osc, 'Style', 'text', 'String', 'Frequency', ...
        'Units', 'normalized', 'Position', [0.05, 0.80, 0.9, 0.10], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'HorizontalAlignment','center');

    % NEW: Frequency Value Display (e.g. "440 Hz")
    gui_handles.txt_freq = uicontrol('Parent', pnl_osc, 'Style', 'text', ...
        'String', '440 Hz', ...
        'Units', 'normalized', 'Position', [0.05, 0.70, 0.9, 0.10], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_acc, 'FontSize', 12, ...
        'FontWeight', 'bold');

    % Frequency Slider
    uicontrol('Parent', pnl_osc, 'Style', 'slider', ...
        'Min', 50, 'Max', 1000, 'Value', 440, ...
        'Units', 'normalized', 'Position', [0.1, 0.55, 0.8, 0.12], ...
        'Callback', @gui_freq_change);

    % Waveform
    uicontrol('Parent', pnl_osc, 'Style', 'text', 'String', 'Waveform', ...
        'Units', 'normalized', 'Position', [0.05, 0.40, 0.9, 0.10], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'HorizontalAlignment','center');

    uicontrol('Parent', pnl_osc, 'Style', 'popupmenu', ...
        'String', {'sine', 'square', 'saw', 'triangle'}, ...
        'Value', 1, ...
        'Units', 'normalized', 'Position', [0.1, 0.28, 0.8, 0.12], ...
        'Callback', @gui_wave_change);

    % Volume
    uicontrol('Parent', pnl_osc, 'Style', 'text', 'String', 'Master Volume', ...
        'Units', 'normalized', 'Position', [0.05, 0.15, 0.9, 0.10], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', [1 0.8 0.4], ...
        'HorizontalAlignment','center');

    uicontrol('Parent', pnl_osc, 'Style', 'slider', ...
        'Min', 0, 'Max', 1.0, 'Value', 0.5, ...
        'Units', 'normalized', 'Position', [0.1, 0.02, 0.8, 0.12], ...
        'Callback', @gui_vol_change);

    % --- BOTTOM CENTER: ENVELOPE (ADSR) ---
    pnl_adsr = uipanel('Parent', f, 'Title', ' ENVELOPE ', ...
        'TitlePosition', 'centertop', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'Position', [0.34, 0.32, 0.30, 0.28], 'BorderType', 'line', ...
        'HighlightColor', [0.3 0.3 0.3]);

    % Attack
    uicontrol('Parent', pnl_adsr, 'Style', 'text', 'String', 'A', ...
        'Units', 'normalized', 'Position', [0.05, 0.80, 0.18, 0.1], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt);
    
    gui_handles.s_att = uicontrol('Parent', pnl_adsr, 'Style', 'slider', ...
        'Min', 0.01, 'Max', 2.0, 'Value', 0.02, ...
        'Units', 'normalized', 'Position', [0.05, 0.15, 0.18, 0.65], ...
        'Callback', {@gui_adsr_change, 1});

    % Decay
    uicontrol('Parent', pnl_adsr, 'Style', 'text', 'String', 'D', ...
        'Units', 'normalized', 'Position', [0.28, 0.80, 0.18, 0.1], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt);

    gui_handles.s_dec = uicontrol('Parent', pnl_adsr, 'Style', 'slider', ...
        'Min', 0.01, 'Max', 2.0, 'Value', 0.10, ...
        'Units', 'normalized', 'Position', [0.28, 0.15, 0.18, 0.65], ...
        'Callback', {@gui_adsr_change, 2});

    % Sustain
    uicontrol('Parent', pnl_adsr, 'Style', 'text', 'String', 'S', ...
        'Units', 'normalized', 'Position', [0.51, 0.80, 0.18, 0.1], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt);

    gui_handles.s_sus = uicontrol('Parent', pnl_adsr, 'Style', 'slider', ...
        'Min', 0.0, 'Max', 1.0, 'Value', 0.60, ...
        'Units', 'normalized', 'Position', [0.51, 0.15, 0.18, 0.65], ...
        'Callback', {@gui_adsr_change, 3});

    % Release
    uicontrol('Parent', pnl_adsr, 'Style', 'text', 'String', 'R', ...
        'Units', 'normalized', 'Position', [0.74, 0.80, 0.18, 0.1], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt);

    gui_handles.s_rel = uicontrol('Parent', pnl_adsr, 'Style', 'slider', ...
        'Min', 0.01, 'Max', 3.0, 'Value', 0.10, ...
        'Units', 'normalized', 'Position', [0.74, 0.15, 0.18, 0.65], ...
        'Callback', {@gui_adsr_change, 4});

    % Reset Button
    uicontrol('Parent', pnl_adsr, 'Style', 'pushbutton', 'String', 'Reset Default', ...
        'Units', 'normalized', 'Position', [0.25, 0.02, 0.5, 0.10], ...
        'BackgroundColor', [0.3 0.3 0.3], 'ForegroundColor', 'white', ...
        'Callback', @gui_adsr_reset);

    % Save GUI handles to figure for easy access
    guidata(f, gui_handles);

    % --- BOTTOM RIGHT: PLAYER ---
    pnl_play = uipanel('Parent', f, 'Title', ' SEQUENCER ', ...
        'TitlePosition', 'centertop', 'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'Position', [0.66, 0.32, 0.32, 0.28], 'BorderType', 'line', ...
        'HighlightColor', [0.3 0.3 0.3]);

    uicontrol('Parent', pnl_play, 'Style', 'text', 'String', 'Select Track:', ...
        'Units', 'normalized', 'Position', [0.05, 0.75, 0.9, 0.10], ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt);

    uicontrol('Parent', pnl_play, 'Style', 'popupmenu', ...
        'String', {'User Melody (Oorum Blood)', 'Harivarasanam (Exact)'}, ...
        'Value', 1, ...
        'Units', 'normalized', 'Position', [0.05, 0.60, 0.9, 0.15], ...
        'Callback', @gui_song_select);

    uicontrol('Parent', pnl_play, 'Style', 'pushbutton', 'String', 'PLAY SONG', ...
        'Units', 'normalized', 'Position', [0.05, 0.25, 0.45, 0.30], ...
        'BackgroundColor', c_green, 'ForegroundColor', 'white', 'FontSize', 10, 'FontWeight', 'bold', ...
        'Callback', @gui_play_song);

    uicontrol('Parent', pnl_play, 'Style', 'pushbutton', 'String', 'STOP', ...
        'Units', 'normalized', 'Position', [0.55, 0.25, 0.40, 0.30], ...
        'BackgroundColor', c_red, 'ForegroundColor', 'white', 'FontSize', 10, 'FontWeight', 'bold', ...
        'Callback', @gui_stop_song);

    % --- BOTTOM STRIP: MANUAL KEYS ---
    pnl_keys = uipanel('Parent', f, 'Title', ' MANUAL CONTROL ', ...
        'TitlePosition', 'centertop', 'FontSize', 10, ...
        'BackgroundColor', c_pnl, 'ForegroundColor', c_txt, ...
        'Position', [0.02, 0.02, 0.96, 0.28]);

    uicontrol('Parent', pnl_keys, 'Style', 'pushbutton', 'String', 'HOLD NOTE (Gate On)', ...
        'Units', 'normalized', 'Position', [0.3, 0.3, 0.2, 0.4], ...
        'BackgroundColor', c_green, 'ForegroundColor', 'white', 'FontWeight', 'bold', ...
        'Callback', @gui_note_on);

    uicontrol('Parent', pnl_keys, 'Style', 'pushbutton', 'String', 'RELEASE (Gate Off)', ...
        'Units', 'normalized', 'Position', [0.5, 0.3, 0.2, 0.4], ...
        'BackgroundColor', [0.3 0.3 0.3], 'ForegroundColor', 'white', 'FontWeight', 'bold', ...
        'Callback', @gui_note_off);

    % Handles & Timer
    handles.plotLine = hLine;
    handles.device = audioDeviceWriter('SampleRate', 44100);

    if evalin('base','exist(''synth_handles'',''var'')')
        try
            old = evalin('base','synth_handles');
            if isvalid(old.timer), stop(old.timer); delete(old.timer); end
            release(old.device);
        catch, end
    end

    t = timer('ExecutionMode','fixedRate','Period',2048/44100, ...
        'TimerFcn',@audio_step,'BusyMode','drop','TasksToExecute',Inf);
    
    handles.timer = t;
    assignin('base','synth_handles',handles);
    start(t);

    %% ---------------- 3. Audio Engine (State Machine) ----------------
    function audio_step(~,~)
        try
            ctrl = evalin('base','synth_control');
            st = evalin('base','synth_state');
            h = evalin('base','synth_handles');
            dev = h.device;

            f_curr = double(ctrl.freq);
            w_curr = char(ctrl.wave);
            gate = double(ctrl.gate);
            adsr = double(ctrl.adsr);
            vol = double(ctrl.volume);

            phase = double(st.phase);
            env = double(st.env_level);
            state = double(st.adsr_state);
            p_out = double(st.prev_out);

            n = 2048; fs = 44100;

            % --- ADSR PARAMETERS ---
            att_rate = 1/(adsr(1)*fs + 1);
            dec_rate = 1/(adsr(2)*fs + 1);
            sus_lvl = adsr(3);
            rel_rate = 1/(adsr(4)*fs + 1);

            % --- OSCILLATOR ---
            f_vec = linspace(st.prev_freq, f_curr, n);
            p_inc = f_vec / fs;
            p_arr = phase + cumsum(p_inc) - p_inc(1);
            p_arr = mod(p_arr, 1);

            y_raw = waveform_vec(w_curr, p_arr);

            % --- ENVELOPE STATE MACHINE ---
            % 0:Idle, 1:Attack, 2:Decay, 3:Sustain, 4:Release
            env_c = zeros(1,n);
            for k=1:n
                if gate == 1
                    if state == 0 || state == 4
                        state = 1; % Start Attack
                    end
                else
                    if state ~= 0 && state ~= 4
                        state = 4; % Start Release
                    end
                end

                switch state
                    case 1 % Attack
                        env = env + att_rate;
                        if env >= 1.0, env = 1.0; state = 2; end
                    case 2 % Decay
                        env = env - dec_rate;
                        if env <= sus_lvl, env = sus_lvl; state = 3; end
                    case 3 % Sustain
                        env = sus_lvl;
                    case 4 % Release
                        env = env - rel_rate;
                        if env <= 0, env = 0; state = 0; end
                    case 0 % Idle
                        env = 0;
                end
                env_c(k) = env;
            end

            y = y_raw .* env_c;

            % --- FILTER ---
            alpha = 0.49;
            y_out = zeros(1,n);
            for k=1:n
                p_out = alpha*p_out + (1-alpha)*y(k);
                y_out(k) = p_out;
            end
            y_out = y_out * vol;

            dev(y_out');

            if isvalid(h.plotLine), set(h.plotLine, 'YData', y_out); end

            st.phase = mod(phase + sum(p_inc),1);
            st.prev_freq = f_curr;
            st.prev_out = p_out;
            st.env_level = env;
            st.adsr_state = state;
            assignin('base','synth_state',st);
        catch
        end
    end

    %% ---------------- 4. Callbacks ----------------
    function gui_freq_change(src, ~)
        val = get(src, 'Value');
        c = evalin('base', 'synth_control');
        c.freq = val;
        assignin('base', 'synth_control', c);
        
        % Update the Text Display
        h = guidata(src);
        set(h.txt_freq, 'String', sprintf('%.0f Hz', val));
    end

    function gui_wave_change(src, ~)
        opts = get(src, 'String');
        c = evalin('base', 'synth_control');
        c.wave = opts{get(src, 'Value')};
        assignin('base', 'synth_control', c);
    end

    function gui_vol_change(src, ~)
        c = evalin('base', 'synth_control');
        c.volume = get(src, 'Value');
        assignin('base', 'synth_control', c);
    end

    function gui_adsr_change(src, ~, idx)
        c = evalin('base', 'synth_control');
        c.adsr(idx) = get(src, 'Value');
        assignin('base', 'synth_control', c);
    end

    function gui_adsr_reset(src, ~)
        % Retrieve slider handles from GUI data
        h = guidata(src);
        c = evalin('base', 'synth_control');
        c.adsr = c.adsr_default;
        assignin('base', 'synth_control', c);

        % Visually Snap Sliders back
        set(h.s_att, 'Value', c.adsr(1));
        set(h.s_dec, 'Value', c.adsr(2));
        set(h.s_sus, 'Value', c.adsr(3));
        set(h.s_rel, 'Value', c.adsr(4));
        fprintf('ADSR Reset.\n');
    end

    function gui_song_select(src, ~)
        c = evalin('base', 'synth_control');
        c.song_choice = get(src, 'Value');
        assignin('base', 'synth_control', c);
    end

    function gui_note_on(~, ~)
        c = evalin('base', 'synth_control');
        c.gate = 1; assignin('base', 'synth_control', c);
    end

    function gui_note_off(~, ~)
        c = evalin('base', 'synth_control');
        c.gate = 0; assignin('base', 'synth_control', c);
    end

    function gui_stop_song(~, ~)
        c = evalin('base', 'synth_control');
        c.stop_signal = 1; c.gate = 0;
        assignin('base', 'synth_control', c);
    end

    function gui_play_song(~, ~)
        c_base = evalin('base', 'synth_control');
        song_idx = c_base.song_choice;
        
        c_orig = evalin('base', 'synth_control');
        c_orig.stop_signal = 0;
        assignin('base', 'synth_control', c_orig);

        C4=261.63; D4=293.66; E4=329.63; F4=349.23; G4=392.00;
        A4=440.00; C5=523.25;

        if song_idx == 1
            % OORUM BLOOD
            melody = [D4 F4 F4 F4, E4 F4 F4 F4, E4 G4 F4 E4, D4 E4 D4 C4];
            durations = repmat(0.18, 1, length(melody));
            play_sequence(melody, durations, 0.05);

        elseif song_idx == 2
            % HARIVARASANAM (Exact)
            T = 0.16; S = 0.25; L = 0.50;
            
            l1_n = [D4,D4,D4, D4, D4,E4]; l1_d = [T, T, T, L, S, S];
            play_sequence(l1_n, l1_d, 0.05); wait_gap(1.0);

            l2_n = [E4,G4, E4, D4,D4]; l2_d = [S, S, L, S, S];
            play_sequence(l2_n, l2_d, 0.05); wait_gap(1.0);

            l3_n = [C4,D4,E4, D4, D4,D4]; l3_d = [T, T, T, L, S, S];
            play_sequence(l3_n, l3_d, 0.05); wait_gap(1.0);

            l4_n = [C4, E4, E4,D4, D4, D4,D4]; l4_d = [L, L, S, S, L, S, S];
            play_sequence(l4_n, l4_d, 0.05); wait_gap(2.0);

            l5_n = [G4,A4,A4, A4, A4,A4]; l5_d = [T, T, T, L, S, S];
            play_sequence(l5_n, l5_d, 0.05); wait_gap(0.5);

            l6_n = [G4,E4, G4,A4,A4, A4, A4,A4]; l6_d = [S, S, T, T, T, L, S, S];
            play_sequence(l6_n, l6_d, 0.05); wait_gap(1.0);

            l7_n = [A4,C5,C5, C5, C5,C5]; l7_d = [T, T, T, L, S, S];
            play_sequence(l7_n, l7_d, 0.05); wait_gap(1.0);

            l8_n = [A4,G4, E4,G4, E4, E4,E4, D4]; l8_d = [S, S, S, S, L, S, S, L];
            play_sequence(l8_n, l8_d, 0.05);
        end
        
        c = evalin('base', 'synth_control');
        c.gate = 0;
        assignin('base', 'synth_control', c);
    end

    function play_sequence(notes, durs, artic_gap)
        for i = 1:length(notes)
            c = evalin('base', 'synth_control');
            if c.stop_signal == 1, return; end
            
            c.freq = notes(i);
            c.gate = 1;
            assignin('base', 'synth_control', c);
            wait_gap(durs(i));
            
            c.gate = 0; assignin('base', 'synth_control', c);
            wait_gap(artic_gap);
        end
    end

    function wait_gap(duration)
        t_start = tic;
        while toc(t_start) < duration
            drawnow;
            chk = evalin('base', 'synth_control');
            if chk.stop_signal == 1
                chk.gate = 0; assignin('base', 'synth_control', chk);
                error('STOPPED');
            end
        end
    end

    function close_app(src, ~)
        try
            h = evalin('base','synth_handles');
            stop(h.timer); delete(h.timer); release(h.device);
        catch, end
        evalin('base','clear synth_handles synth_control synth_state');
        delete(src);
    end

    function y = waveform_vec(wname, phase_arr)
        switch lower(wname)
            case 'sine'
                y = sin(2*pi*phase_arr);
            case 'square'
                y = sign(sin(2*pi*phase_arr));
            case 'saw'
                % Manual sawtooth calculation (No Toolbox needed)
                y = 2 * (phase_arr - floor(phase_arr + 0.5));
            case 'triangle'
                % Manual triangle calculation (No Toolbox needed)
                y = 2 * abs(2 * (phase_arr - floor(phase_arr + 0.5))) - 1;
            otherwise
                y = sin(2*pi*phase_arr);
        end
    end

end
