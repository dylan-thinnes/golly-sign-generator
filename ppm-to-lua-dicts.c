#include <stdio.h>

int main () {
  FILE* rf = fopen("r.lua", "w");
  FILE* gf = fopen("g.lua", "w");
  FILE* bf = fopen("b.lua", "w");

  int height, width, prec;
  printf("%d\n", scanf("P6\n%d %d\n%d\n", &width, &height, &prec));

  fprintf(rf, "local sign = {\n");
  fprintf(gf, "local sign = {\n");
  fprintf(bf, "local sign = {\n");

  for (int yy = 0; yy < height; yy++) {
    fprintf(rf, "  {");
    fprintf(gf, "  {");
    fprintf(bf, "  {");
    for (int xx = 0; xx < width; xx++) {
      int r = getc(stdin);
      int g = getc(stdin);
      int b = getc(stdin);
      fprintf(rf, "%d,", r != 0);
      fprintf(gf, "%d,", g != 0);
      fprintf(bf, "%d,", b != 0);
    }
    fprintf(rf, "},\n");
    fprintf(gf, "},\n");
    fprintf(bf, "},\n");
  }

  fprintf(rf, "}");
  fprintf(gf, "}");
  fprintf(bf, "}");

  fclose(rf);
  fclose(gf);
  fclose(bf);
}
