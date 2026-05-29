shader_type canvas_item;

// Cattura quello che c'è sotto il ColorRect
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Nello shader, imposta i range e i default neutri
uniform float blur_lod : hint_range(0.0, 5.0) = 0.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0; // 1.0 è il contrasto normale
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint_color : source_color = vec3(1.0, 0.9, 0.6); // Giallino tipico

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // 1. Blur (usando i Mipmaps della texture dello schermo)
    vec4 col = textureLod(screen_texture, uv, blur_lod);
    
    // 2. Desaturazione (perdita di vivacità dei colori)
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(col.rgb, vec3(lum), desaturation);
    
    // 3. Contrasto
    col.rgb = (col.rgb - 0.5) * contrast + 0.5;
    
    // 4. Tinta gialligna (ingiallimento del cristallino)
    col.rgb = mix(col.rgb, tint_color, tint_amount);
    
    COLOR = col;
}