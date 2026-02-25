@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption tabla TAREA'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_TAREA as projection on ZI_TAREA
{
    key Uuid,
    UuidOrden,
    Posicion,
    Descripcion,
    Status,
    DuracionHoras,
    Tecnico,
    FechaEjecucion,
    CreatedAt,
    CrearedBy,
    LastChangedAt,
    LastChangedBy,
    /* Associations */
    _OrdenTrabajo : redirected to parent ZC_ORDENTRABAJO
}
