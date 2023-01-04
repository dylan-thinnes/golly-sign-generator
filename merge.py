import cv2
r = cv2.imread("r.ppm")
g = cv2.imread("g.ppm")
b = cv2.imread("b.ppm")
cv2.imwrite("out.ppm", cv2.merge((b[:,:,1], g[:,:,1], r[:,:,1])))
r[:,:,1] = 0
r[:,:,2] = 0
g[:,:,0] = 0
g[:,:,2] = 0
b[:,:,0] = 0
b[:,:,1] = 0
cv2.imwrite("r.ppm", r)
cv2.imwrite("b.ppm", g)
cv2.imwrite("g.ppm", b)
