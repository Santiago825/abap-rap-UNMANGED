@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'INTERFACE TAREA'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_TAREA as select from ZTTAREA
    association to parent ZI_ORDEN_TRABAJO as _OrdenTrabajo
        on $projection.UuidOrden =_OrdenTrabajo.Uuid
{
    key uuid as Uuid,
    uuid_orden as UuidOrden,
    posicion as Posicion,
    descripcion as Descripcion,
    status as Status,
    duracion_horas as DuracionHoras,
    tecnico as Tecnico,
    fecha_ejecucion as FechaEjecucion,
    created_at as CreatedAt,
    creared_by as CrearedBy,
    last_changed_at as LastChangedAt,
    last_changed_by as LastChangedBy,
    _OrdenTrabajo
}
