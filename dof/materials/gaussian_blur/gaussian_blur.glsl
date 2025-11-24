#ifndef DOF_GAUSSIAN_BLUR_GLSL
#define DOF_GAUSSIAN_BLUR_GLSL

const float PI = 3.141592653589793;

// OFFSETS  and WEIGHTS Can be static for performance:
// https://lisyarus.github.io/blog/posts/blur-coefficients-generator.html
// Calculate Gaussian weight
float gaussian(float x, float sigma)
{
    float sigma2 = sigma * sigma;
    return exp(-(x * x) / (2.0 * sigma2)) / sqrt(2.0 * PI * sigma2);
}

#endif