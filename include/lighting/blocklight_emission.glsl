#if !defined INCLUDE_LIGHTING_BLOCKLIGHT_EMISSION
#define INCLUDE_LIGHTING_BLOCKLIGHT_EMISSION



#include "/include/utility/color.glsl"


float calculate_light_source_mask(
    uint material_mask,
    vec3 albedo_raw,
    vec3 world_pos,
    inout vec3 emission_color
) {
    float light_source_mask = 1.0;
    float albedo_luminance = length(albedo_raw);
    vec3 block_pos = fract(world_pos);
    
    emission_color = vec3(0.0);
    

    
    if (material_mask == 10020u || material_mask == 10021u || 
        material_mask == 10023u || material_mask == 10024u || 
        material_mask == 10026u || material_mask == 10030u || 
        material_mask == 10033u || material_mask == 10034u) {

        float red_glow = float(albedo_raw.r > 0.8 || albedo_raw.r > albedo_raw.g * 1.4);
        float yellow_glow = float(albedo_raw.r > 0.7 && albedo_raw.g > 0.6 && albedo_raw.b < 0.4);
        float glow_mask = max(red_glow, yellow_glow);

        light_source_mask = mix(0.05, 1.0, glow_mask);
        
    
        emission_color = 6.0 * glow_mask * albedo_raw;
    }
    

    else if (material_mask == 10015u) {
      
        float fire_intensity = cube(albedo_luminance);
        light_source_mask = 0.1;
        emission_color = 6.0 * fire_intensity * albedo_raw;
    }
    


    else if (material_mask == 10031u || material_mask == 10032u) {
     
        float is_copper = float(
            albedo_raw.r > 0.4 && albedo_raw.r < 0.8 &&
            albedo_raw.g > 0.3 && albedo_raw.g < 0.6 &&
            albedo_raw.b > 0.2 && albedo_raw.b < 0.5 &&
            albedo_raw.r > albedo_raw.g * 1.1 &&
            albedo_raw.g > albedo_raw.b * 1.0
        );
        
  
        float emission_strength = mix(4.0, 0.3, is_copper);
        emission_color = emission_strength * cube(albedo_luminance) * albedo_raw;
        light_source_mask = 0.05;
    }
    
   

    else if (material_mask == 10061u) {
  
        float is_lit = float(albedo_raw.r > 0.70 && albedo_raw.g > 0.55 && albedo_raw.b < 0.50);
        
    
        float is_copper_shell = float(
            albedo_raw.r > 0.40 && albedo_raw.r < 0.78 &&
            albedo_raw.g > 0.25 && albedo_raw.g < 0.55 &&
            albedo_raw.b < 0.35 &&
            albedo_raw.r > albedo_raw.b * 1.8
        );
        
        float light_mask = is_lit * (1.0 - is_copper_shell);
        light_source_mask = mix(1.0, 0.01, light_mask);
        
    
        vec3 light_color = vec3(3.0, 2.2, 0.9);
        float flicker = 0.94 + 0.06 * sin(frameTimeCounter * 15.0);
        emission_color = 18.0 * light_color * flicker * light_mask;
    }
    

    else if (material_mask == 10025u || material_mask == 10029u) {

        float blue_glow = float(albedo_raw.b > 0.5 || albedo_raw.g > albedo_raw.r * 1.4);
        
        vec3 soul_light_color = vec3(0.2, 0.6, 1.0) * (1.0 + 0.3 * sin(frameTimeCounter * 8.0));
        emission_color = 8.0 * soul_light_color * blue_glow;
        light_source_mask = mix(0.05, 0.03, blue_glow);
    }
    

    else if (material_mask == 10027u || material_mask == 10028u) {

        float red_emission = 0.0;
        
        if (material_mask == 10027u) {
     
            if (fract(world_pos.y + cameraPosition.y) > 0.18) {
                red_emission = step(0.65, albedo_raw.r);
            } else {
                red_emission = step(1.25, albedo_raw.r / (albedo_raw.g + albedo_raw.b + 0.001)) * 
                              step(0.5, albedo_raw.r);
            }
        } else {
           
            red_emission = smoothstep(0.3, 0.9, albedo_raw.r) * 
                          step(albedo_raw.r, albedo_raw.g * 2.0);
        }
        
        emission_color = vec3(2.1, 0.9, 0.9) * 8.0 * red_emission;
        light_source_mask = mix(1.0, 0.05, red_emission);
    }
    

    else if (material_mask >= 10035u && material_mask <= 10050u) {

        

        if (material_mask == 10041u) {
            float is_lapis = clamp01(
                (max(max(dot(albedo_raw, vec3(2.0, -1.0, -1.0)),
                        dot(albedo_raw, vec3(-1.0, 2.0, -1.0))),
                    dot(albedo_raw, vec3(-1.0, -1.0, 2.0))) - 0.1) / 0.3
            );
            emission_color = pow(max(albedo_raw - vec3(0.1), vec3(0.0)), vec3(5.0)) * is_lapis * 2.0;
            light_source_mask = max(0.15, 1.0 - is_lapis * 0.85);
        }
      
        else if (material_mask == 10040u) {
            float is_emerald = clamp01(dot(albedo_raw, vec3(-20.0, 30.0, 10.0)));
            vec3 emerald_bright = max(albedo_raw - vec3(0.1), vec3(0.0));
            emission_color = (emerald_bright * emerald_bright * emerald_bright) * is_emerald * 2.0;
            light_source_mask = max(0.15, 1.0 - is_emerald * 0.85);
        }

        else if (material_mask == 10039u) {
            float is_diamond = float(albedo_raw.b > albedo_raw.r * 1.2 && 
                                    albedo_raw.g > albedo_raw.r * 1.1 &&
                                    albedo_luminance > 0.3);
            emission_color = pow(albedo_raw, vec3(3.0)) * is_diamond * 1.5;
            light_source_mask = max(0.2, 1.0 - is_diamond * 0.8);
        }
    }
    

    else if (material_mask == 10016u) {
  
        float is_warm_yellow = float(
            (albedo_raw.r > 0.65 && albedo_raw.g > 0.55 && albedo_raw.b < 0.50) ||
            (albedo_raw.r > 0.70 && albedo_raw.g > 0.60 && albedo_raw.r > albedo_raw.g * 1.02)
        );
        
        vec3 warm_glow = vec3(1.0, 0.85, 0.4) * (0.85 + 0.15 * sin(frameTimeCounter * 3.0));
        emission_color = 4.5 * warm_glow * cube(albedo_luminance) * is_warm_yellow;
        light_source_mask = mix(1.0, 0.06, is_warm_yellow);
    }
    

    else if (material_mask == 10062u) {
      
        float is_purple = float(albedo_raw.b > albedo_raw.r && albedo_raw.b > albedo_raw.g);
        float pulse = 0.75 + 0.25 * sin(frameTimeCounter * 2.0);
        
        emission_color = is_purple * vec3(0.5, 0.2, 1.0) * pulse * 6.0 * cube(albedo_luminance);
        light_source_mask = 0.08;
    }
    

    else if (material_mask == 10063u) {
  
        vec3 mid_block_pos = abs(block_pos - 0.5);
        float edge_dist = max(max(mid_block_pos.x, mid_block_pos.y), mid_block_pos.z);
        float outline_strength = smoothstep(0.45, 0.5, edge_dist);
        
        emission_color = albedo_luminance + 2.0 * outline_strength * vec3(0.6, 0.2, 1.0);
        light_source_mask = 0.05;
    }
    

    
    return light_source_mask;
}

vec3 apply_integrated_blocklight(
    vec3 base_color,
    vec3 blocklight_contribution,
    uint material_mask,
    vec3 albedo_raw,
    vec3 world_pos,
    float ao
) {
    vec3 emission_color;
    float light_source_mask = calculate_light_source_mask(
        material_mask, 
        albedo_raw, 
        world_pos,
        emission_color
    );
    

    vec3 result = base_color * mix(0.1, 1.0, light_source_mask);
    

    result += blocklight_contribution * light_source_mask;
    

    result += emission_color * ao;
    
    return result;
}

#endif // INCLUDE_LIGHTING_BLOCKLIGHT_EMISSION
