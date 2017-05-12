########################################
use Test::More tests => 8;
########################################
{
    BEGIN { use_ok('Vector::Object3D') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Polygon') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Line') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Point') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Point::Cast') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Point::Transform') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Matrix') };
}
########################################
{
    BEGIN { use_ok('Vector::Object3D::Matrix::Transform') };
}
########################################
