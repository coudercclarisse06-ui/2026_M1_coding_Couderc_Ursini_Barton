function total_volume = Snowman_task1b_V1(r)
 totvol7snowmen = 0
 for k = 1:7                                            % Boucle sur les 7 bonhommes
    % 1. Rayon de la tete
    r_head = r / 3;

    % 2. Volumes des 2 spheres
    vol_body = (4/3) * pi * (r^3);
    vol_head = (4/3) * pi * (r_head^3);

    % 3. Ajout au cumul (comme en Python)
    totvol7snowmen += vol_body + vol_head;

    % 4. Rayon augmente de 10% pour le prochain bonhomme
    r *= 1.10;
 endfor
 totvol7snowmen
endfunction
