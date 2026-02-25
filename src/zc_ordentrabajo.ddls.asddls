@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption tabla ORDEN TRABAJO'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_ORDENTRABAJO
  provider contract transactional_query 
  as projection on ZI_ORDEN_TRABAJO
{
    key Uuid,
    OrdenNum,
    Descripcion,
    Status,
    FechaInicio,
    FechaFin,
    Responsable,
    CreatedAt,
    CrearedBy,
    LastChangedAt,
    LastChangedBy,
    /* Associations */
    _Tareas :redirected to composition child ZC_TAREA
}
