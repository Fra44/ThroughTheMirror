shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Intensità dell'effetto (0.0 = normale, 1.0 = massimo)
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 original = texture(screen_texture, SCREEN_UV);
    vec3 c = original.rgb;

    // Matrice di simulazione per Deuteranopia (scritta colonna per colonna)
    mat3 deuteranopia_mat = mat3(
        vec3(0.625, 0.700, 0.000), // Colonna R
        vec3(0.375, 0.300, 0.300), // Colonna G
        vec3(0.000, 0.000, 0.700)  // Colonna B
    );

    // Applica la trasformazione moltiplicando la matrice per il colore originale
    vec3 transformed = deuteranopia_mat * c;

    // Applica l'intensità scelta tramite interpolazione lineare
    COLOR.rgb = mix(c, transformed, intensity);
    COLOR.a = original.a;
}